# DiscordStrategy = require('passport-discord').Strategy
# passport = require 'passport'

request = require 'request'
so2 = require 'simple-oauth2'

isMikuia = (Mikuia.settings.bot.name == 'Mikuia')

oAuthInfo =
	site: 'https://discordapp.com'
	clientID: Mikuia.settings.plugins.discord.clientId
	clientSecret: Mikuia.settings.plugins.discord.clientSecret
	tokenPath: '/api/oauth2/token'
	authorizationPath: '/api/oauth2/authorize'

oauth2 = so2 oAuthInfo
authUri = oauth2.authCode.authorizeURL
	redirect_uri: Mikuia.settings.plugins.discord.callbackBasePath + '/auth/discord/callback'
	scope: 'identify connections'

Mikuia.Plugin.getManifest('discord').settings.channel.serverId.link.url = 'https://discordapp.com/oauth2/authorize?&client_id=' + oAuthInfo.clientID + '&response_type=code&scope=bot+identify+guilds&permissions=224264&redirect_uri=' + Mikuia.settings.plugins.discord.callbackBasePath + '/dashboard/plugins/discord/callback'

checkAuth = (req, res, next) ->
	if req.isAuthenticated()
		return next()
	else
		req.session.redirectTo = req.path
		res.redirect '/login'

linkDiscordAccount = (discordId, username) =>
	Channel = new Mikuia.Models.Channel username
	await
		Channel.setSetting 'discord', 'userId', discordId, defer whatever
		Mikuia.Database.hset 'plugin:discord:users', discordId, Channel.getName(), defer whatever

linkDiscordServer = (serverId, username) =>
	Channel = new Mikuia.Models.Channel username
	await
		Channel.setSetting 'discord', 'serverId', serverId, defer whatever
		Mikuia.Database.hset 'plugin:discord:servers', serverId, Channel.getName(), defer whatever

Mikuia.Web.get '/auth/discord', (req, res) =>
	res.redirect authUri

Mikuia.Web.get '/auth/discord/callback', (req, res, next) =>
	token = oauth2.authCode.getToken
		code: req.query.code
		redirect_uri: 'http://dev.mikuia.tv/auth/discord/callback'
	, (err, result) =>
		if !err
			token = oauth2.accessToken.create result
			await 
				oauth2.api 'GET', '/api/users/@me',
					access_token: token.token.access_token
				, defer err2, userData

				oauth2.api 'GET', '/api/users/@me/connections',
					access_token: token.token.access_token
				, defer err3, connectionData
			
			if !err2 and !err3
				twitchChannels = 0
				twitchIndex = null

				if connectionData?
					for connection, i in connectionData
						if connection.type == 'twitch'
							twitchChannels++
							twitchIndex = i

				if twitchChannels == 1
					linkDiscordAccount userData.id, connectionData[twitchIndex].name
					res.render '../../plugins/discord/views/linked',
						discord: userData
				else
					console.log 'we need to keep up the good work'
					if req.isAuthenticated()
						linkDiscordAccount userData.id, req.user.username
						res.render '../../plugins/discord/views/linked',
							discord: userData
					else
						req.session.discord = userData
						req.session.redirectTo = '/auth/discord/continue'
						res.redirect '/login'
			else
				res.send 'epic fail'
		else
			res.send 'fail'

Mikuia.Web.get '/auth/discord/continue', checkAuth, (req, res) =>
	if req.session.discord?
		linkDiscordAccount req.session.discord.id, req.user.username
	res.render '../../plugins/discord/views/linked',
		discord: req.session.discord

Mikuia.Web.get '/dashboard/plugins/discord/callback', checkAuth, (req, res) =>
	token = oauth2.authCode.getToken
		code: req.query.code
		redirect_uri: 'http://dev.mikuia.tv/dashboard/plugins/discord/callback'
	, (err, result) =>
		if !err
			token = oauth2.accessToken.create result
			await 
				oauth2.api 'GET', '/api/users/@me/guilds',
					access_token: token.token.access_token
				, defer err2, guildData

			if !err2

				for guild in guildData
					if guild.id == req.query.guild_id
						if guild.owner
							linkDiscordServer guild.id, req.user.username
							res.render '../../plugins/discord/views/server',
								guild: guild
								ownerFailure: false
						else
							res.render '../../plugins/discord/views/server',
								guild: guild
								ownerFailure: true
			else
				res.send 'epic fail'
		else
			res.send 'fail'

# 	failureRedirect: '/'
# ), (req, res) =>
# 	res.redirect '/auth/discord/info'
# Mikuia.Web.get '/auth/discord/info', (req, res) =>
# 	console.log req.user
# 	req.send 'Hi'
