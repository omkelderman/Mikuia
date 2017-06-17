cli = require 'cli-color'
fs = require 'fs'
irc = require 'irc'
request = require 'request'
RateLimiter = require('limiter').RateLimiter
_ = require 'underscore'

banchoLimiter = new RateLimiter 1, 'second'
limits = {}
userBest = {}
userData = {}

modes = [
	'osu!'
	'Taiko'
	'Catch the Beat'
	'osu!mania'
]

patterns = [/(http|https):\/\/(?!osu.ppy.sh\/).+/ig]

twitchCommands = [
	'ban'
	'clear'
	'host'
	'r9kbeta'
	'r9kbetaoff'
	'slow'
	'slowoff'
	'subscribers'
	'subscribersoff'
	'timeout'
	'unban'
	'unhost'
]

# Crucial stuff, whatever!

osuLeaderboard = new Mikuia.Models.Leaderboard 'osuRankMode0'
taikoLeaderboard = new Mikuia.Models.Leaderboard 'osuRankMode1'
ctbLeaderboard = new Mikuia.Models.Leaderboard 'osuRankMode2'
omLeaderboard = new Mikuia.Models.Leaderboard 'osuRankMode3'

leaderboard = [
	osuLeaderboard
	taikoLeaderboard
	ctbLeaderboard
	omLeaderboard
]

insertStars = (length) =>
	string = ''
	for i in [1..length]
		string += '*'
	return string

banchoSay = (name, message) =>
	banchoLimiter.removeTokens 1, (err, rr) =>
		cleanMessage = message

		for pattern in patterns
			matches = []
			while match = pattern.exec message
				matches.push match

			for match in matches
				if match?
					message = message.replace match[0], insertStars match[0].length
					fs.appendFileSync 'logs/osu/' + name + '.txt', 'Mikuia: ' + cleanMessage + '\n'

		if Mikuia.settings.bot.debug
			Mikuia.Log.info cli.magentaBright('osu!') + cli.whiteBright(' / ') + cli.yellowBright('=> ' + name + ': ') + cli.whiteBright(message)

		@bancho.say name, message

checkForRequest = (user, Channel, message, target, details) =>
	continueCheck = true
	await Channel.getSetting 'osu', 'requestSubMode', defer err, requestSubMode
	if !err && requestSubMode && user?
		if not user.subscriber
			continueCheck = false

	await Channel.getSetting 'osu', 'requestUserLimit', defer err, requestUserLimit
	if !err && requestUserLimit && user?
		if limits[Channel.getName()]?.users?[user.username]?
			if (new Date()).getTime() < limits[Channel.getName()].users[user.username] + (requestUserLimit * 1000)
				continueCheck = false

	await Channel.getSetting 'osu', 'requestIgnoreMyself', defer err, requestIgnoreMyself
	if !err && requestIgnoreMyself && user?
		if user.username == Channel.getName()
			continueCheck = false

	if continueCheck
		if /osu.ppy.sh\/(b|s)\/(\d+)/g.test message
			match = /osu.ppy.sh\/(b|s)\/(\d+)/g.exec message

			await
				Channel.getSetting 'osu', 'name', defer err, username
				Channel.getSetting 'osu', 'mode', defer err2, mode

			if !err && username != ''
				await getBeatmap match[2], match[1], defer err, beatmaps
				if !err && beatmaps.length
					switch match[1]
						when 'b'
							sendRequest Channel, user, username, beatmaps[0], message, target, details
						when 's'
							customModes = false
							preferredMode = '0'
							if !err2
								preferredMode = mode

							maps = []
							for i, map of beatmaps
								if map.mode == preferredMode
									maps.push map

							if maps.length == 0
								maps = beatmaps
								preferredMode = '0'

							highestDifficultyRating = 0
							highestDifficultyMap = null

							for i, map of maps
								if map.difficultyrating > highestDifficultyRating && map.mode == preferredMode
									highestDifficultyRating = map.difficultyrating
									highestDifficultyMap = map

							if !highestDifficultyMap
								for i, map of maps
									if map.difficultyrating > highestDifficultyRating
										highestDifficultyRating = map.difficultyrating
										highestDifficultyMap = map

							sendRequest Channel, user, username, highestDifficultyMap, message, target, details

updateUserBest = (stream, callback) =>
	await Mikuia.Database.hget 'mikuia:stream:' + stream, 'game', defer err, game
	if err or !game? or game.toLowerCase() != 'osu!'
		callback err, null
	else
		Channel = new Mikuia.Models.Channel stream
		await
			Channel.getDisplayName defer error, displayName
			Channel.getSetting 'osu', 'name', defer err, name
			Channel.getSetting 'osu', 'mode', defer err2, mode
		if !err && name?
			if err2
				mode = 0

			await getUserBest name, mode, defer err, best
			if !userBest[name]?
				userBest[name] = {}
			else if best?
				for score, i in best
					if (new Date(score.date)).getTime() > userBest[name].timeUpdated

						await
							Channel.getSetting 'osu', 'topRanks', defer err, topRanks
							Channel.getSetting 'osu', 'topRankFormat', defer err2, topRankFormat

						formatData = _.extend {}, score,
							rank: i + 1

						console.log cli.whiteBright.bgCyan (new Date(score.date)).getTime() + '>' + userBest[name].timeUpdated
						console.log cli.cyanBright name + ' got a new top rank! #' + (i + 1) + ' - ' + score.beatmap_id + ' - ' + score.pp + 'pp!'
						if topRanks
							Mikuia.Chat.say Channel.getName(), Mikuia.Format.parse topRankFormat, formatData

			userBest[name][mode] = best

			# 6 hour difference between osu! servers...
			userBest[name].timeUpdated = (new Date()).getTime() + (7 * 60 * 60 * 1000)
			Mikuia.Log.info cli.magentaBright('osu!') + ' / ' + cli.cyan(displayName) + ' / ' + cli.whiteBright('Updated best ranks for ' + cli.cyanBright(name) + '.')
		callback false, null

checkRankUpdates = (stream, callback) =>
	await Mikuia.Database.hget 'mikuia:stream:' + stream, 'game', defer err, game
	if err or !game? or game.toLowerCase() != 'osu!'
		callback err, null
	else
		Channel = new Mikuia.Models.Channel stream
		await Channel.getSetting 'osu', 'updates', defer err, updates
		if err
			callback err, null
		else
			await
				Channel.getSetting 'osu', 'name', defer err, name
				Channel.getSetting 'osu', 'mode', defer err2, mode
				Channel.getSetting 'osu', 'events', defer err3, events
			if err || !name?
				callback err, null
			else
				if err2
					mode = 0

				await
					getUser name, mode, defer err, stats
					Mikuia.Database.hset 'plugin:osu:channels', name, Channel.getName(), defer errar, whatever

				if err
					callback true, null
				else if stats?[0]?
					stats = stats[0]

					if userData[name]?[mode]?
						data = userData[name][mode]

						leaderboard[mode].setScore stream, stats.pp_rank

						if data.pp_raw != stats.pp_raw
							pp_change = stats.pp_raw - data.pp_raw
							rank_change = stats.pp_rank - data.pp_rank
							acc_change = stats.accuracy - data.accuracy

							if pp_change >= 0
								pp_updown = 'up'
								pp_sign = '+'
							else
								pp_updown = 'down'
								pp_sign = ''

							if rank_change >= 0
								rank_updown = 'lost'
								rank_sign = ''
							else
								rank_updown = 'gained'
								rank_sign = '+'
								rank_change *= -1

							if acc_change >= 0
								acc_updown = 'up'
								acc_sign = '+'
							else
								acc_updown = 'down'
								acc_sign = ''

							await
								Channel.getSetting 'osu', 'ppChangeFormat', defer err, ppChangeFormat
								Channel.getSetting 'osu', 'rankChangeFormat', defer err, rankChangeFormat
								Channel.getSetting 'osu', 'updateDelay', defer err, updateDelay
							if !err && updates
								Mikuia.Log.info 'Delaying updates for ' + Channel.getName() + ' by ' + (updateDelay * 1000) + '...'
								setTimeout () =>
									ppMessage = Mikuia.Format.parse ppChangeFormat,
										pp_new: stats.pp_raw
										pp_old: data.pp_raw
										pp_change: pp_change
										pp_updown: pp_updown
										pp_sign: pp_sign

									rankMessage = Mikuia.Format.parse rankChangeFormat,
										rank_new: stats.pp_rank
										rank_old: data.pp_rank
										rank_change: rank_change
										rank_updown: rank_updown
										rank_sign: rank_sign
										acc_new: stats.accuracy
										acc_old: data.accuracy
										acc_change: acc_change
										acc_updown: acc_updown
										acc_sign: acc_sign

									if rank_change != 0
										message = ppMessage + rankMessage
									else
										message = ppMessage

									Mikuia.Chat.say Channel.getName(), message

								, updateDelay * 1000
								callback false, null
							else
								callback true, null
						else
							callback false, null
					else
						callback false, null

					if !userData[name]?
						userData[name] = {}

					userData[name][mode] = stats

					if !err3 && events
						if userData[name]?.lastEventDate? && stats?.events?[0]?.date?
							if (new Date(stats.events[0].date)).getTime() > userData[name].lastEventDate
								await
									Channel.getSetting 'osu', 'eventDelay', defer err, delay
									Channel.getSetting 'osu', 'eventRankFormat', defer err2, eventRankFormat
									Channel.getSetting 'osu', 'eventMinRank', defer err3, eventMinRank
								if !err && !err2 && !err3
									match = /images\/([A-Z]+)_small.+\/u\/(\d+).+achieved (?:<b>)?rank #(\d+)(?:<\/b>)? on .+\/b\/(\d+).+'>(.*) \[(.*)\].+\((.*)\)/.exec stats.events[0].display_html
									if match?
										grade = match[1]
										user_id = match[2]
										rank = match[3]
										beatmap_id = match[4]
										mapName = match[5]
										version = match[6]
										mode = match[7]

										if rank <= parseInt(eventMinRank)
											setTimeout () =>
												Mikuia.Chat.say Channel.getName(), Mikuia.Format.parse eventRankFormat,
													user_id: user_id
													username: name
													rank: rank
													beatmap_id: beatmap_id
													mapName: mapName
													version: version
													mode: mode
													grade: grade
											, delay * 1000

					if stats?.events?[0]?.date?
						userData[name].lastEventDate = (new Date(stats.events[0].date)).getTime()
				else
					callback false, null

makeAPIRequest = (link, callback) =>
	start = process.hrtime()
	request 'https://osu.ppy.sh/api' + link + '&k=' + @Plugin.getSetting('apiKey'), (error, response, body) ->
		responseTime = parseInt(process.hrtime(start)[1] / 10000000, 10)

		if !error && response.statusCode == 200
			Mikuia.Events.emit 'osu.api.request', responseTime

			data = {}
			try
				data = JSON.parse body
			catch e
				console.log e
			callback false, data
		else
			callback true, null

makeTillerinoRequest = (beatmap_id, mods, callback) =>
	start = process.hrtime()
	request 
		url: 'https://api.tillerino.org/beatmapinfo?k=' + @Plugin.getSetting('tillerinoKey') + '&wait=2000&beatmapid=' + beatmap_id + '&mods=' + mods
		timeout: 2000
	, (error, response, body) ->
		responseTime = parseInt(process.hrtime(start)[1] / 10000000, 10)

		if !error && response.statusCode == 200
			Mikuia.Events.emit 'osu.tillerino.request', responseTime

			data = {}
			try
				data = JSON.parse body
			catch e
				console.log e
			callback false, data
		else
			callback true, null

sendRequest = (Channel, user, username, map, message, target, details) =>
	if map?
		continueRequest = true

		await Channel.getSetting 'osu', 'requestMapLimit', defer err, requestMapLimit
		if !err && requestMapLimit
			if limits[Channel.getName()]?.maps?[map.beatmapset_id]?
				if (new Date()).getTime() < limits[Channel.getName()].maps[map.beatmapset_id] + (requestMapLimit * 1000)
					continueRequest = false

		await
			Channel.getSetting 'osu', 'requestMinStars', defer err, requestMinStars
			Channel.getSetting 'osu', 'requestMaxStars', defer err2, requestMaxStars
		
		if !err && !err2
			requestMinStars = parseFloat requestMinStars
			requestMaxStars = parseFloat requestMaxStars

			if requestMinStars > parseFloat(map.difficultyrating)
				continueRequest = false

			if requestMaxStars < parseFloat(map.difficultyrating)
				continueRequest = false

		await Channel.getSetting 'osu', 'requestMinStatus', defer err, requestMinStatus
		if !err

			# 1 is Ranked, 2 is Approved - fuck you too, osu!
			sensibleMappings =
				"-2": 0
				"-1": 1
				"0": 2
				"1": 5
				"2": 4
				"3": 3

			if sensibleMappings[map.approved] < parseInt(requestMinStatus)
				continueRequest = false

		if continueRequest
			await
				Channel.getSetting 'osu', 'chatRequestFormat', defer err, chatRequestFormat
				Channel.getSetting 'osu', 'osuRequestFormat', defer err2, osuRequestFormat
				Channel.getSetting 'osu', 'requestChatInfo', defer err3, requestChatInfo

			modValue = 0
			modString = ''

			if message.toLowerCase().indexOf('+v') > -1
				modString += '+Video'

			if message.toLowerCase().indexOf('+sb') > -1
				modString += '+Storyboard'

			if message.toLowerCase().indexOf('+dt') > -1
				modValue += 64
				modString += '+DoubleTime'
			if message.toLowerCase().indexOf('+nc') > -1
				modValue += 512
				modString += '+Nightcore'
			if message.toLowerCase().indexOf('+hr') > -1
				modValue += 16
				modString += '+HardRock'
			if message.toLowerCase().indexOf('+hd') > -1
				modValue += 8
				modString += '+Hidden'
			if message.toLowerCase().indexOf('+ez') > -1
				modValue += 2
				modString += '+Easy'
			if message.toLowerCase().indexOf('+ht') > -1
				modValue += 256
				modString += '+HalfTime'
			if message.toLowerCase().indexOf('+so') > -1
				modValue += 4096
				modString += '+SpunOut'
			if message.toLowerCase().indexOf('+nf') > -1
				modValue += 1
				modString += '+NoFail'

			if map.approved > 0
				await makeTillerinoRequest map.beatmap_id, modValue, defer err4, tillerinoData

			accuracies = {}
			maxRange = 0
			maxRangeString = ''
			minRange = 0
			minRangeString = ''
			wholeString = ''

			if userBest[username]?[map.mode]?
				best = userBest[username][map.mode]

				if best[0]?.pp? && best[24]?.pp?
					maxRange = best[0].pp
					minRange = best[24].pp

			if tillerinoData?.ppForAcc?.entry?
				maxDiff = 0
				minDiff = 0
				for entry in tillerinoData.ppForAcc.entry
					if !maxDiff
						maxDiff = maxRange - entry.value
						maxRangeString = (Math.round(entry.value * 100) / 100) + 'pp for ' + (entry.key * 100) + '%'
						minDiff = minRange - entry.value
						minRangeString = (Math.round(entry.value * 100) / 100) + 'pp for ' + (entry.key * 100) + '%'

					else
						if maxDiff > Math.abs(maxRange - entry.value)
							maxDiff = Math.abs(maxRange - entry.value)
							maxRangeString = (Math.round(entry.value * 100) / 100) + 'pp for ' + (entry.key * 100) + '%'

						if minDiff > Math.abs(minRange - entry.value)
							minDiff = Math.abs(minRange - entry.value)
							minRangeString = (Math.round(entry.value * 100) / 100) + 'pp for ' + (entry.key * 100) + '%'

				if minRangeString == maxRangeString
					wholeString = minRangeString
				else
					wholeString = minRangeString + ' | ' + maxRangeString
			else
				if err4
					wholeString = 'Tillerino down'
				else
					wholeString = 'no pp data'

			modeText = 'osu!'
			approvedText = 'Ranked'
			switch map.mode
				when '1' then modeText = 'Taiko'
				when '2' then modeText = 'Catch the Beat'
				when '3' then modeText = 'osu!mania'

			switch map.approved
				when '3' then approvedText = 'Qualified'
				when '2' then approvedText = 'Approved'
				when '0' then approvedText = 'Pending'
				when '-1' then approvedText = 'WIP'
				when '-2' then approvedText = 'Graveyard'

			if user?
				Requester = new Mikuia.Models.Channel user.username
				await Requester.getDisplayName defer err, requesterDisplayName
			else
				requesterDisplayName = '<Anonymous>'

			data =
				requester: requesterDisplayName
				beatmapset_id: map.beatmapset_id
				beatmap_id: map.beatmap_id
				approved: map.approved
				approved_date: map.approved_date
				approvedText: approvedText
				last_update: map.last_update
				total_length: map.total_length
				hit_length: map.hit_length
				version: map.version
				artist: map.artist
				title: map.title
				creator: map.creator
				bpm: map.bpm
				source: map.source
				difficultyrating: map.difficultyrating
				diff_size: map.diff_size
				diff_overall: map.diff_overall
				diff_approach: map.diff_approach
				diff_drain: map.diff_drain
				mode: map.mode
				modeText: modeText
				modString: modString
				ppString: wholeString

			if !limits[Channel.getName()]?
				limits[Channel.getName()] =
					maps: {}
					users: {}

			limits[Channel.getName()].maps[map.beatmapset_id] = (new Date()).getTime()

			if user?
				limits[Channel.getName()].users[user.username] = (new Date()).getTime()

			# Chat
			if !err && requestChatInfo
				Mikuia.Chat.handleResponse user.username, Channel.getName(), Mikuia.Format.parse(chatRequestFormat, data), target, details

			# osu!
			if !err2
				banchoSay username.split(' ').join(''), Mikuia.Format.parse osuRequestFormat, data

# API functions.

getBeatmap = (id, type, callback) ->
	await makeAPIRequest '/get_beatmaps?' + type + '=' + id, defer err, data
	callback err, data

getUser = (name, mode, callback) ->
	await makeAPIRequest '/get_user?u=' + name + '&m=' + mode + '&type=string', defer err, data
	callback err, data

getUserBest = (name, mode, callback) ->
	await makeAPIRequest '/get_user_best?u=' + name + '&m=' + mode + '&type=string&limit=100', defer err, data
	callback err, data

Mikuia.Events.on 'twitch.connected', =>
	@bancho = new irc.Client('irc.ppy.sh', @Plugin.getSetting('name'),
		userName: @Plugin.getSetting 'name'
		password: @Plugin.getSetting 'password'
		port: 6667
		autoRejoin: true
		autoConnect: true
		sasl: false
		realName: 'Mikuia - a Twitch.tv bot // http://mikuia.tv'
	)

	@bancho.on 'error', (error) =>
		console.log error

	@bancho.on 'registered', =>
		Mikuia.Log.info cli.magentaBright('osu!') + ' / ' + cli.whiteBright('Logged in to Bancho as ' + @Plugin.getSetting('name') + '.')

	@bancho.on 'pm', (from, message, event) =>
		Mikuia.Log.info cli.magentaBright('osu!') + ' / ' + cli.whiteBright(from) + ': ' + message
		fs.appendFileSync 'logs/' + from + '.txt', from + ': ' + message + '\n'
		if message == @Plugin.getSetting 'verifyCommand'
			code = Math.floor(Math.random() * 900000) + 100000
			await Mikuia.Database.setex 'plugin:osu:auth:code:' + code, 60, from, defer error, whatever

			banchoSay from, 'Your code is ' + code + '. You have only a minute to save the wo... I mean to put it on page...'
		else
			if message.indexOf('!') == 0
				tokens = message.split ' '
				trigger = tokens[0].replace '!', ''

				if trigger in twitchCommands

					await Mikuia.Database.hget 'plugin:osu:channels', from, defer err, name

					if name?
						Channel = new Mikuia.Models.Channel name

						await
							Channel.getSetting 'osu', 'name', defer err, osuName
							Channel.isSupporter defer err, isSupporter

						if osuName == from
							if isSupporter
								Mikuia.Chat.sayUnfiltered name, message.split('!').join('.')
							else
								banchoSay from, 'This feature is available only for Mikuia Supporters.'

	for word in @Plugin.getSetting('blockedWords')
		patterns.push new RegExp word, 'ig'

Mikuia.Events.on 'twitch.message', (user, to, message) =>
	Channel = new Mikuia.Models.Channel to
	await Channel.isPluginEnabled 'osu', defer err, enabled

	if !err && enabled
		await Channel.getSetting 'osu', 'requests', defer err, requestsEnabled
		if !err && requestsEnabled
			checkForRequest user, Channel, message, 'twitch', {}

Mikuia.Events.on 'osu.np', (data) ->
	Mikuia.Chat.handleResponse data.user.username, data.to, 'Darude - Sandstorm', data.settings._target, data.details

Mikuia.Events.on 'osu.request', (data) =>
	Channel = new Mikuia.Models.Channel data.to
	checkForRequest data.user, Channel, data.message, data.settings._target, data.details

Mikuia.Events.on 'osu.stats', (data) =>
	tokens = data.tokens.slice 0
	tokens.splice 0, 1
	username = tokens.join ' '

	mode = 0

	Channel = new Mikuia.Models.Channel data.to
	await Channel.getCommandSettings data.tokens[0], true, defer err2, settings

	if !err2
		if settings.username? && settings.username != ''
			username = settings.username
		if settings.mode?
			mode = settings.mode

	if username == ''
		await Channel.getSetting 'osu', 'name', defer err, name
		if !err && name?
			username = name

	if username != ''
		await getUser username, mode, defer err, user
		if !err && user?[0]?.username?
			message = Mikuia.Format.parse data.settings.format,
				username: user[0].username
				id: user[0].user_id
				rank: user[0].pp_rank
				pp: user[0].pp_raw
				count300: user[0].count300
				count100: user[0].count100
				count50: user[0].count50
				playcount: user[0].playcount
				ranked_score: user[0].ranked_score
				total_score: user[0].total_score
				level: user[0].level
				accuracy: user[0].accuracy
				rank_ss: user[0].count_rank_ss
				rank_s: user[0].count_rank_s
				rank_a: user[0].count_rank_a
				country: user[0].country

			Mikuia.Chat.handleResponse data.user.username, Channel.getName(), message, data.settings._target, data.details

# Updating ranks!

setInterval () =>
	await Mikuia.Streams.getAll defer err, streams
	if !err && streams?
		for stream in streams
			await checkRankUpdates stream, defer err, status
, 15000

setInterval () =>
	await Mikuia.Streams.getAll defer err, streams
	if !err && streams?
		for stream in streams
			await updateUserBest stream, defer err, whatever
, 30000

Mikuia.Events.on 'twitch.updated', =>
	if Object.keys(userBest).length == 0
		await Mikuia.Streams.getAll defer err, streams
		if !err && streams?
			for stream in streams
				await updateUserBest stream, defer err, whatever
