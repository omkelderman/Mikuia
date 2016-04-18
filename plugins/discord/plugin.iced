cli = require 'cli-color'
Discord = require 'discord.io'

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
			Channel = new Mikuia.Models.Channel twitchChannel

			await
				Channel.isPluginEnabled 'discord', defer err2, isPluginEnabled
				Mikuia.Database.hget 'plugin:discord:users', userId, defer err3, twitchUser

			if !err2 and isPluginEnabled

				if twitchUser?
					users[twitchUser] = userId

					user =
						username: twitchUser
						subscriber: false
						color: '#ffffff'

					Mikuia.Chat.handleMessage user, twitchChannel, message, 'discord',
						discordChannelId: channelId

				else
					Mikuia.Chat.handleMessage null, twitchChannel, message, 'discord',
						anonymous: true
						discordChannelId: channelId

	Mikuia.Events.on 'mikuia.say.custom', (data) =>
		switch data.target
			when 'discord'
				if data.details?.discordChannelId?
					discord.sendMessage
						to: data.details.discordChannelId
						message: '<@' + users[data.username] + '>: ' + data.message

			when 'discord_private'
				discord.sendMessage
					to: users[data.username]
					message: '**[' + data.channel + ']** ' + data.message