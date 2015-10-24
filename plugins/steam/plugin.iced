cli = require 'cli-color'
crypto = require 'crypto'
fs = require 'fs'

Steam = require 'steam'

exports.bot = bot = new Steam.SteamClient()
exports.friends = friends = new Steam.SteamFriends bot
exports.user = user = new Steam.SteamUser bot
joinedChannel = {}

bot.connect()
bot.on 'connected', ->
	loginDetails =
		account_name: Mikuia.settings.plugins.steam.accountName
		password: Mikuia.settings.plugins.steam.password

	if Mikuia.settings.plugins.steam.authCode != ''
		loginDetails.auth_code = Mikuia.settings.plugins.steam.authCode

	await fs.readFile 'sentry.sha', defer err, sentryFile
	if not err
		loginDetails.sha_sentryfile = crypto.createHash('sha1').update(sentryFile).digest()

	user.logOn loginDetails

bot.on 'logOnResponse', (response) ->
	console.log response
	if response.eresult == Steam.EResult.OK
		friends.setPersonaState Steam.EPersonaState.Online
		friends.setPersonaName 'Mikuia'

		Mikuia.Events.emit 'steam.connected'

bot.on 'loggedOff', ->
	console.log 'Logged off.'
	bot.disconnect()
	bot.connect()

bot.on 'error', (e) ->
	console.log 'Error: ' + e

user.on 'updateMachineAuth', (authData, callback) ->
	fs.writeFileSync 'sentry.sha', authData.bytes
	callback
		sha_file: crypto.createHash('sha1').update(authData.bytes).digest()

friends.on 'friend', (steamId, relationshipType) ->
	if relationshipType == Steam.EFriendRelationship.PendingInvitee
		friends.addFriend steamId

if not Mikuia.settings.bot.debug
	friends.on 'friendMsg', (steamId, message, type) ->
		if type == Steam.EChatEntryType.ChatMsg and steamId in Mikuia.settings.plugins.steam.whitelist
			if message.indexOf('/') == 0
				tokens = message.replace('/', '').split ' '
				trigger = tokens[0]
				switch trigger
					when 'help'
						friends.sendMessage steamId, 'There is no help for you D:'

					when 'join'
						channelName = tokens[1].toLowerCase()
						joinedChannel[steamId] = channelName
						friends.sendMessage steamId, 'Joined #' + channelName + '!'

					when 'leave'
						channelName = joinedChannel[steamId]
						delete joinedChannel[steamId]
						friends.sendMessage steamId, 'Left #' + channelName + '!'

					when 'status'
						if joinedChannel[steamId]?
							friends.sendMessage steamId, 'Status: on #' + joinedChannel[steamId] + '.'
						else
							friends.sendMessage steamId, 'Status: -'
			else
				if joinedChannel[steamId]?
					message = message.trim()
					if message.indexOf('.') != 0
						Mikuia.Chat.say joinedChannel[steamId], message
				else
					friends.sendMessage steamId, 'You have to join a channel! Use /join <channel>!'
		else
			console.log steamId + ' (' + type + ')'

	Mikuia.Events.on 'twitch.message', (user, to, message) =>
		for steamId, channelName of joinedChannel
			if to == '#' + channelName
				friends.sendMessage steamId, user.username + ': ' + message