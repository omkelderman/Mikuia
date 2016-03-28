cli = require 'cli-color'
irc = require 'tmi.js'
RateLimiter = require('limiter').RateLimiter
RollingLimiter = require 'rolling-rate-limiter'

channelContext = {}
channelLimiter = {}
channelTotalLimiter = {}
whisperUserLimiter = {}

class exports.Chat
	constructor: (@Mikuia) ->
		@chatters = {}
		@channelClients = {}
		@clientJoins = {}
		@clients = {}
		@commandCooldowns = {}
		@connected = false
		@joined = []
		@messageLimiter = null
		@moderators = {}
		@nextJoinClient = 0
		@whisperClient = null
		@whisperLimiter = null

	broadcast: (message) =>
		await Mikuia.Streams.getAll defer err, streams
		for stream in streams
			@say stream, '.me broadcast: ' + message

	checkMod: (channel, username) =>
		if channel == '#' + username
			return true
		else
			moderators = @mods channel
			moderators? and username in moderators

	connect: =>
		connections = Mikuia.settings.bot.connections

		if connections < 1
			connections = 1

		setTimeout () =>
			if !@connected
				@Mikuia.Log.fatal cli.magenta('Twitch') + ' / ' + cli.whiteBright('Failed to connect to Twitch chat. Restarting...')
		, connections * 10 * 1000

		for i in [0..(connections - 1)]
			await @spawnConnection i, defer err, client
			@clients[i] = client
			@clientJoins[i] = []

		@whisperClient = new irc.client
			options:
				debug: @Mikuia.settings.bot.debug
			connection:
				reconnect: true
				cluster: 'group'
				port: '80'
			identity:
				username: @Mikuia.settings.bot.name
				password: @Mikuia.settings.bot.oauth

		@whisperClient.on 'whisper', (user, message) =>
			@handleWhisper user, message

		@whisperClient.on 'connected', (address, port) =>
			@Mikuia.Log.info cli.magenta('Twitch') + ' / ' + cli.whiteBright('Connected to Twitch group chat (' + cli.yellowBright(address + ':' + port) + cli.whiteBright(')'))

		@whisperClient.on 'disconnected', (reason) =>
			@Mikuia.Log.fatal cli.magenta('Twitch') + ' / ' + cli.whiteBright('Disconnected from Twitch group chat. Reason: ' + reason)

		@whisperClient.on 'notice', (channel, noticeId, params) =>
			@Mikuia.Log.info cli.magenta('Twitch') + ' / ' + cli.whiteBright('Received a notice: ') + cli.yellowBright(noticeId)

		@whisperClient.connect()

		@joinLimiter = RollingLimiter
			interval: 10000
			maxInInterval: 49
			namespace: 'mikuia:join:limiter'
			redis: Mikuia.Database

		@messageLimiter = RollingLimiter
			interval: 30000
			maxInInterval: 19
			namespace: 'mikuia:chat:limiter:'
			redis: Mikuia.Database

		@whisperLimiter = RollingLimiter
			interval: 60000
			maxInInterval: 99
			minDifference: 500
			namespace: 'mikuia:whisper:limiter'
			redis: Mikuia.Database

		@parseQueue()
		@parseWhispers()

	getChatters: (channel) => @chatters[channel]

	handleMessage: (user, to, message, forceWhisper) =>
		Channel = new @Mikuia.Models.Channel to
		Chatter = new @Mikuia.Models.Channel user.username
		await
			Channel.getDisplayName defer err, displayName
			Chatter.isBanned defer err, isBanned

		channelContext[user.username] =
			channel: Channel.getName()
			user: user

		chatterUsername = cli.yellowBright user.username

		if Chatter.isAdmin()
			chatterUsername = cli.redBright user.username

		if Chatter.isModOf Channel.getName()
			chatterUsername = cli.greenBright '[m] ' + chatterUsername

		if user.subscriber
			chatterUsername = cli.blueBright '[s] ' + chatterUsername

		if not forceWhisper
			if message.toLowerCase().indexOf(Mikuia.settings.bot.name.toLowerCase()) > -1 || message.toLowerCase().indexOf(Mikuia.settings.bot.admin) > -1
				@Mikuia.Log.info cli.cyanBright('[' + @channelClients['#' + Channel.getName()] + ']') + ' / ' + cli.bgBlackBright(cli.cyan(displayName) + ' / ' + chatterUsername + ': ' + cli.red(message))

		if !isBanned
			@Mikuia.Events.emit 'twitch.message', user, to, message, forceWhisper

		Channel.trackIncrement 'messages', 1

		tokens = message.split ' '
		trigger = tokens[0]

		inChatters = false
		for categoryName, category of @getChatters Channel.getName()
			if category.indexOf(user.username) > -1
				inChatters = true
		if !inChatters
			@chatters[Channel.getName()] ?= { viewers: [] }
			@chatters[Channel.getName()].viewers.push user.username

		await Channel.queryCommand trigger, user, defer err, o
		{command, settings, isAllowed, reasons} = o

		if forceWhisper
			settings._whisper = true

		if not settings?._cooldown
			settings._cooldown = 2

		if settings._cooldown > 0
			if not @commandCooldowns[Channel.getName()]?
				@commandCooldowns[Channel.getName()] = {}

			if not @commandCooldowns[Channel.getName()][trigger]?
				@commandCooldowns[Channel.getName()][trigger] = (new Date()).getTime()
			else
				if @commandCooldowns[Channel.getName()][trigger] + (settings._cooldown * 1000) > (new Date()).getTime()
					reasons.push 'cooldown'
				else
					@commandCooldowns[Channel.getName()][trigger] = (new Date()).getTime()

		if err then reasons.push 'database'
		if isBanned then reasons.push 'banned'

		if command?
			if not reasons.length
				handler = @Mikuia.Plugin.getHandler command

				if handler?.plugin?
					await Channel.isPluginEnabled handler.plugin, defer err, enabled

					if enabled
						if settings?._coinCost and settings._coinCost > 0
							User = new Mikuia.Models.Channel user.username
							await Mikuia.Database.zincrby "channel:#{Channel.getName()}:coins", -settings._coinCost, user.username, defer error, whatever

						@Mikuia.Events.emit command, {user, to, message, tokens, settings}
						Channel.trackIncrement 'commands', 1
					else
						reasons.push 'disabled'

			@Mikuia.Events.emit 'mikuia.command',
				handler: command
				channel: Channel.getName()
				user: user
				message: message
				tokens: tokens
				settings: settings
				status:
					failure: reasons.length > 0 ? true : false
					reason: reasons

	handleWhisper: (user, message) =>
		if channelContext[user.username]?.channel?
			@handleMessage user, channelContext[user.username].channel, message, true
		else
			@whisper user.username, 'Unknown channel context. Please say something on the channel you\'re active in!'

	join: (channel, callback) =>
		if channel.indexOf('#') == -1
			channel = '#' + channel

		Channel = new Mikuia.Models.Channel channel
		await
			Channel.isBanned defer err, isBanned
			Channel.isEnabled defer err, isMember
			Channel.isPrioritized defer err, isPrioritized

		if @joined.indexOf(channel) == -1 and isMember and !isBanned
			await Mikuia.Database.zrangebyscore 'mikuia:join:limiter', '-inf', '+inf', defer err, limitEntries

			currentTime = (new Date).getTime() * 1000
			remainingRequests = 49

			for limitEntry in limitEntries
				if parseInt(limitEntry) + 15000000 > currentTime
					remainingRequests--

			if remainingRequests > 0
				@joinLimiter '', (err, timeLeft) =>
					if not timeLeft
						if @nextJoinClient >= Mikuia.settings.bot.connections
							@nextJoinClient = 0

						if not isPrioritized
							clientIdToUse = @nextJoinClient
							@nextJoinClient++
						else
							await @spawnConnection Channel.getName(), defer err, @clients[Channel.getName()]
							@clientJoins[Channel.getName()] = []
							clientIdToUse = Channel.getName()

						@clients[clientIdToUse].join channel
						@clientJoins[clientIdToUse].push channel
						@channelClients[channel] = clientIdToUse
						@commandCooldowns[Channel.getName()] = {}
						@joined.push channel
						callback? false

					else
						callback? true
			else
				callback? true
		else
			callback? true

	joinMultiple: (channels, callback) =>
		for channel, i in channels
			await @join channel, defer whatever

		callback false

		for channel in channels
			await @updateChatters channel, defer whatever

	mods: (channel) =>
		@moderators[channel.replace('#', '')]

	parseQueue: =>
		await Mikuia.Database.lpop 'mikuia:chat:queue', defer err, jsonData
		if jsonData
			data = JSON.parse jsonData

			Channel = new Mikuia.Models.Channel data.channel
			await Channel.getDisplayName defer err, displayName

			if channelLimiter[Channel.getName()]? and @channelClients['#' + Channel.getName()]?
				channelLimiter[Channel.getName()].removeTokens 1, (err, channelRR) =>
					if channelRR > -1
						await Mikuia.Database.zrangebyscore 'mikuia:chat:limiter:' + @channelClients['#' + Channel.getName()], '-inf', '+inf', defer err, limitEntries

						currentTime = (new Date).getTime() * 1000
						remainingRequests = 19

						for limitEntry in limitEntries
							if parseInt(limitEntry) + 30000000 > currentTime
								remainingRequests--

						if remainingRequests > 0
							@messageLimiter @channelClients['#' + Channel.getName()], (err, timeLeft) =>
								if !timeLeft
									@clients[@channelClients['#' + Channel.getName()]].say data.channel, data.message.split('%%WORKER%%').join(@channelClients['#' + Channel.getName()])

									@Mikuia.Log.info cli.cyanBright('[' + @channelClients['#' + Channel.getName()] + ']') + ' / ' + cli.cyan(displayName) + ' / ' + cli.magentaBright(@Mikuia.settings.bot.name) + ' (' + cli.magentaBright(remainingRequests) + ') (' + cli.greenBright(Math.floor(channelRR)) + '): ' + data.message

									@parseQueue()
								else
									await Mikuia.Database.lpush 'mikuia:chat:queue', jsonData, defer whatever

									setTimeout () =>
										@parseQueue()
									, 30000
						else
							#await Mikuia.Database.zrangebyscore 'mikuia:chat:limiter:' + channelClients[Channel.getName()], '-inf', '+inf', defer err, lastRequestTimes
							#lastRequestTime = lastRequestTimes[0]
							#currentTime = (new Date).getTime() * 1000
							#waitTime = Math.floor((30000000 - (currentTime -  lastRequestTime)) / 1000)

							setTimeout () =>
								@parseQueue()
							, 100

					else
						await Mikuia.Database.rpush 'mikuia:chat:queue', jsonData, defer whatever
						setTimeout () =>
							@parseQueue()
						, 10

			else
				setTimeout () =>
					@parseQueue()
				, 10

		else
			setTimeout () =>
				@parseQueue()
			, 100

	parseWhispers: =>
		await Mikuia.Database.lpop 'mikuia:whisper:queue', defer err, jsonData
		if jsonData
			data = JSON.parse jsonData

			if !whisperUserLimiter[data.username]?
				whisperUserLimiter[data.username] = new RateLimiter 2, 3000, true

			whisperUserLimiter[data.username].removeTokens 1, (err, userRR) =>
				if userRR > -1
					await Mikuia.Database.zrangebyscore 'mikuia:whisper:limiter', '-inf', '+inf', defer err, limitEntries

					currentTime = (new Date).getTime() * 1000
					remainingRequests = 99

					for limitEntry in limitEntries
						if parseInt(limitEntry) + 60000000 > currentTime
							remainingRequests--

					if remainingRequests > 0
						@whisperLimiter '', (err, timeLeft) =>
							if !timeLeft
								@whisperClient.whisper data.username, data.message

								Mikuia.Events.emit 'mikuia.whisper', data.username, data.message

								setTimeout () =>
									@parseWhispers()
								, 500
							else
								await Mikuia.Database.lpush 'mikuia:whisper:queue', jsonData, defer whatever

								setTimeout () =>
									@parseWhispers()
								, 60000
					else
						setTimeout () =>
							@parseWhispers()
						, 100
				else
					await Mikuia.Database.rpush 'mikuia:whisper:queue', jsonData, defer whatever
					setTimeout () =>
						@parseWhispers()
					, 10
		else
			setTimeout () =>
				@parseWhispers()
			, 10

	part: (channel) =>
		if channel.indexOf('#') == -1
			channel = '#' + channel

		if @channelClients[channel]?
			@clients[@channelClients[channel]].part channel
			if @joined.indexOf(channel) > -1
				@joined.splice @joined.indexOf(channel), 1
			delete @channelClients[channel]

	say: (channel, message) =>
		if channel.indexOf('#') == -1
			channel = '#' + channel
		if message.indexOf('.') == 0 or message.indexOf('/') == 0
			message = '!' + message.replace('.', '').replace('/', '')

		@sayUnfiltered channel, message

	sayUnfiltered: (channel, message) ->
		Channel = new Mikuia.Models.Channel channel

		if channelTotalLimiter[Channel.getName()]
			channelTotalLimiter[Channel.getName()].removeTokens 1, (err, remainingRequests) =>
				if remainingRequests > -1
					lines = message.split '\\n'
					for line in lines
						if !Mikuia.settings.bot.disableChat && line.trim() != ''

							line = JSON.stringify
								channel: channel
								message: line
							await Mikuia.Database.rpush 'mikuia:chat:queue', line, defer whatever

	sayRaw: (channel, message) =>
		@clients[@channelClients[channel]].say channel, message

	spawnConnection: (i, callback) =>
		client = new irc.client
			options:
				debug: @Mikuia.settings.bot.debug
			connection:
				cluster: 'aws'
				reconnect: true
			identity:
				username: @Mikuia.settings.bot.name
				password: @Mikuia.settings.bot.oauth

		client.id = i
		client.connect()

		client.on 'chat', (channel, user, message, self) =>
			if not self
				@handleMessage user, channel, message, false
			else
				Mikuia.Events.emit 'mikuia.say',
					channel: channel
					username: user.username
					user: user
					message: message

		client.on 'connected', (address, port) =>
			@Mikuia.Log.info cli.cyanBright('[' + client.id + ']') + ' / ' + cli.magenta('Twitch') + ' / ' + cli.whiteBright('Connected to Twitch chat (' + cli.yellowBright(address + ':' + port) + cli.whiteBright(')'))

			client.raw 'CAP REQ :twitch.tv/membership'
			client.raw 'CAP REQ :twitch.tv/commands'
			client.raw 'CAP REQ :twitch.tv/tags'

			if client.id == Mikuia.settings.bot.connections - 1
				@Mikuia.Events.emit 'twitch.connected'
				@connected = true
				@update()

			callback false, client

		client.on 'disconnected', (reason) =>
			@Mikuia.Log.fatal cli.cyanBright('[' + client.id + ']') + ' / ' + cli.magenta('Twitch') + ' / ' + cli.whiteBright('Disconnected from Twitch chat. Reason: ' + reason)

		client.on 'join', (channel, username) =>
			if username == @Mikuia.settings.bot.name.toLowerCase()
				Channel = new Mikuia.Models.Channel channel
				await
					Channel.getCleanDisplayName defer err, cleanDisplayName
					Channel.getDisplayName defer err, displayName
					Channel.isPrioritized defer err, isPrioritized
					Channel.isSupporter defer err, isSupporter

				if isPrioritized
					# this is basically handled on a different level so whatever
					channelLimiter[Channel.getName()] = new RateLimiter 1000, 30000, true
					channelTotalLimiter[Channel.getName()] = new RateLimiter 1000, 30000, true
					rateLimitingProfile = cli.magentaBright 'Prioritized (unlimited)'
				else if isSupporter
					channelLimiter[Channel.getName()] = new RateLimiter 5, 30000, true
					channelTotalLimiter[Channel.getName()] = new RateLimiter 10, 30000, true
					rateLimitingProfile = cli.redBright 'Supporter (5 per 30s)'
				else
					channelLimiter[Channel.getName()] = new RateLimiter 3, 30000, true
					channelTotalLimiter[Channel.getName()] = new RateLimiter 6, 30000, true
					rateLimitingProfile = cli.greenBright 'Free (3 per 30s)'

				@Mikuia.Log.info cli.cyanBright('[' + client.id + ']') + ' / ' + cli.cyan(displayName) + ' / ' + cli.whiteBright('Joined the channel. Rate Limiting Profile: ') + rateLimitingProfile

				Mikuia.Events.emit 'mikuia.join',
					channel: Channel.getName()
					displayName: cleanDisplayName

		client.on 'notice', (channel, noticeId, params) =>
			if noticeId == 'msg_banned' || noticeId == 'msg_timedout'
				Channel = new Mikuia.Models.Channel channel
				await
					Channel.getDisplayName defer err, displayName
					Channel.disable defer whatever

				@part Channel.getName()
				@Mikuia.Log.info cli.cyanBright('[' + client.id + ']') + ' / ' + cli.magenta('Twitch') + ' / ' + cli.whiteBright('Banned or timed out on ' + cli.greenBright(displayName) + cli.whiteBright('.'))
				@Mikuia.Events.emit 'twitch.banned',
					channel: Channel.getName()
					displayName: displayName

		client.on 'part', (channel, username) =>
			if username == @Mikuia.settings.bot.name.toLowerCase()
				Channel = new Mikuia.Models.Channel channel
				await Channel.getDisplayName defer err, displayName

				delete channelLimiter[Channel.getName()]
				delete channelTotalLimiter[Channel.getName()]
				@Mikuia.Log.info cli.cyanBright('[' + client.id + ']') + ' / ' + cli.cyan(displayName) + ' / ' + cli.whiteBright('Left the channel.')

	update: =>
		twitchFailure = false

		await @Mikuia.Chat.joinMultiple @Mikuia.settings.bot.autojoin, defer whatever
		await @Mikuia.Database.smembers 'mikuia:channels', defer err, channels
		if err then @Mikuia.Log.error err else
			chunks = @Mikuia.Tools.chunkArray channels, 100
			streamData = {}
			streamList = []

			for chunk, i in chunks
				if chunk.length > 0
					joinList = []
					@Mikuia.Log.info cli.magenta('Twitch') + ' / ' + cli.whiteBright('Checking channels live... (' + (i + 1) + '/' + chunks.length + ')')
					await @Mikuia.Twitch.getStreams chunk, defer err, streams
					if err
						@Mikuia.Log.error err
						twitchFailure = true
					else
						chunkList = []
						for stream in streams
							chunkList.push stream.channel.display_name
							if joinList.indexOf(stream.channel.name) == -1
								joinList.push stream.channel.name
							streamList.push stream
							streamData[stream.channel.name] = stream

							Channel = new Mikuia.Models.Channel stream.channel.name
							Channel.trackValue 'followers', stream.channel.followers
							Channel.trackValue 'viewers', stream.viewers
							Channel.trackValue 'views', stream.views

							await Channel.isSupporter defer err, isSupporter
							if isSupporter
								Channel.trackValue 'supporterValue', Math.floor(Math.random() * 10000) + 1
							else
								Channel.trackValue 'supporterValue', 0

						@Mikuia.Log.info cli.magenta('Twitch') + ' / ' + cli.whiteBright('Obtained live channels... (' + chunkList.length + ')')
						await @Mikuia.Chat.joinMultiple joinList, defer uselessfulness

			await @Mikuia.Database.del 'mikuia:streams', defer err, response
			await
				for stream in streamList
					@Mikuia.Database.sadd 'mikuia:streams', stream.channel.name, defer err, whatever

					things = [
						'broadcaster_language'
						'display_name'
						'followers'
						'game'
						'language'
						'logo'
						'mature'
						'profile_banner'
						'status'
						'views'
					]

					for thing in things
						if stream.channel[thing]? and stream.channel[thing]
							@Mikuia.Database.hset 'mikuia:stream:' + stream.channel.name, thing, stream.channel[thing], defer err, whatever

					@Mikuia.Database.hset 'mikuia:stream:' + stream.channel.name, 'created_at', stream.created_at, defer err, whatever
					@Mikuia.Database.hset 'mikuia:stream:' + stream.channel.name, 'preview', stream.preview.medium, defer err, whatever
					@Mikuia.Database.hset 'mikuia:stream:' + stream.channel.name, 'viewers', stream.viewers, defer err, whatever
					@Mikuia.Database.expire 'mikuia:stream:' + stream.channel.name, 600, defer err, whatever

					if stream.channel.profile_banner? && stream.channel.profile_banner != 'null'
						Channel = new Mikuia.Models.Channel stream.channel.name
						Channel.setProfileBanner stream.channel.profile_banner, defer err, whatever

			@Mikuia.Events.emit 'twitch.updated'

			updateTimeout = streamList.length * 1000
			if updateTimeout < 15000
				updateTimeout = 15000

			setTimeout () =>
				@update()
			, updateTimeout

	updateChatters: (channel, callback) =>
		await Mikuia.Twitch.getChatters channel, defer err, chatters
		if !err
			if chatters.chatters?
				@chatters[channel] = chatters.chatters
			if chatters.chatters?.moderators?
				@moderators[channel] = chatters.chatters.moderators
			Channel = new Mikuia.Models.Channel channel
			Channel.trackValue 'chatters', chatters.chatter_count

		callback err

	whisper: (username, message) =>
		lines = message.split '\\n'
		for line in lines
			if !Mikuia.settings.bot.disableChat && line.trim() != ''
				line = JSON.stringify
					username: username
					message: line
				await Mikuia.Database.rpush 'mikuia:whisper:queue', line, defer whatever
