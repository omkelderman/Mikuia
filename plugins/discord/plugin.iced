cli = require 'cli-color'
Discord = require 'discord.io'

channels = {}
users = {}

if Mikuia.settings.plugins.discord?.token? and Mikuia.settings.plugins.discord.token != 'BOT_USER_TOKEN'
	discord = new Discord
		token: Mikuia.settings.plugins.discord.token
		autorun: true

	discord.on 'disconnected', =>
		discord.connect()

	discord.on 'err', (error) ->
		Mikuia.Log.error cli.blueBright('Discord') + ' / ' + cli.whiteBright('Error:' + error)

	discord.on 'ready', (rawEvent) ->
		Mikuia.Log.info cli.blueBright('Discord') + ' / ' + cli.whiteBright('Connected to Discord.')

		console.log cli.redBright 'discord.io ' + discord.internals.version

		for serverId, server of discord.servers
			console.log cli.cyanBright(serverId + ' - ' + server.name)

	discord.on 'message', (user, userId, channelId, message, rawEvent) =>
		serverId = discord.serverFromChannel channelId

		await Mikuia.Database.hget 'plugin:discord:servers', serverId, defer err, twitchChannel
		if !err and twitchChannel?
			channels[twitchChannel] = serverId
			console.log userId + ' - ' + message + ' - ' + cli.greenBright('Legit channel! (' + twitchChannel + ')')

			await Mikuia.Database.hget 'plugin:discord:users', userId, defer err2, twitchUser
			if !err and twitchUser?
				users[twitchUser] = userId
				console.log userId + ' is ' + cli.greenBright('linked! (' + twitchUser + ')')

				# @handleMessage user, channelContext[user.username].channel, message, 'whisper'
				user =
					username: twitchUser
					subscriber: false
					color: '#ffffff'

				Mikuia.Chat.handleMessage user, twitchChannel, message, 'discord'
			else
				console.log userId + ' is ' + cli.redBright('not linked.')

			# @handleMessage user, channelContext[user.username].channel, message, 'whisper'

		else
			console.log userId + ' - ' + message + ' - ' + cli.redBright('No channel.')

	Mikuia.Events.on 'mikuia.say.custom', (data) =>
		switch data.target
			when 'discord'
				discord.sendMessage
					to: channels[data.channel]
					message: '<@' + users[data.username] + '>: ' + data.message