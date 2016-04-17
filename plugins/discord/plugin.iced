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

	discord.on 'message', (user, userId, channelId, message, rawEvent) =>
		serverId = discord.serverFromChannel channelId

		await Mikuia.Database.hget 'plugin:discord:servers', serverId, defer err, twitchChannel

		if !err and twitchChannel?
			channels[twitchChannel] = serverId

			await Mikuia.Database.hget 'plugin:discord:users', userId, defer err2, twitchUser

			if !err and twitchUser?
				users[twitchUser] = userId

				user =
					username: twitchUser
					subscriber: false
					color: '#ffffff'

				Mikuia.Chat.handleMessage user, twitchChannel, message, 'discord'

	Mikuia.Events.on 'mikuia.say.custom', (data) =>
		switch data.target
			when 'discord'
				discord.sendMessage
					to: channels[data.channel]
					message: '<@' + users[data.username] + '>: ' + data.message