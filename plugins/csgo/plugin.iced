csgo = require 'csgo'
steam = require 'steam'

CSGO = null
GC = null
plugin = null

rankNames = [
	'Unranked'
	'Silver I'
	'Silver II'
	'Silver III'
	'Silver IV'
	'Silver Elite'
	'Silver Elite Master'
	'Gold Nova I'
	'Gold Nova II'
	'Gold Nova III'
	'Gold Nova IV'
	'Master Guardian I'
	'Master Guardian II'
	'Master Guardian Elite'
	'Distinguished Master Guardian'
	'Legendary Eagle'
	'Legendary Eagle Master'
	'Supreme Master First Class'
	'The Global Elite'
]

twitchDone = false

launchAndUpdate = =>
	playerCheckQueue = []

	await Mikuia.Streams.getAll defer err, streams
	if not err and streams?
		for stream in streams
			await Mikuia.Database.hget 'mikuia:stream:' + stream, 'game', defer err, game
			if not err and game == 'Counter-Strike: Global Offensive'
				Channel = new Mikuia.Models.Channel stream
				await Channel.isPluginEnabled 'csgo', defer err, enabled

				if enabled
					await
						Channel.getDisplayName defer error, displayName
						Channel.getSetting 'steam', 'steamId', defer err, steamId

					if steamId in Object.keys plugin.friends.personaStates
						if plugin.friends.personaStates[steamId].gameid == '730'
							playerCheckQueue.push steamId

	if plugin.bot.loggedOn and playerCheckQueue.length > 0
		CSGO.launch()

		CSGO.on 'ready', =>
			CSGO.playerProfileRequest CSGO.ToAccountID playerCheckQueue.pop()

			CSGO.on 'playerProfile', (playerProfile) =>
				if playerProfile?.account_profiles?[0]?
					profile = playerProfile.account_profiles[0]

					await Mikuia.Database.hget 'plugin:steam:users', CSGO.ToSteamID profile.account_id, defer err, channel

					if not err and channel
						Channel = new Mikuia.Models.Channel channel

						rank = ""
						wins = ""

						if profile.ranking?.rank_id? then rank = profile.ranking.rank_id
						if profile.ranking?.wins? then wins = profile.ranking.wins

						await
							Channel.setPluginData 'csgo', 'rank', rank, defer whatever
							Channel.setPluginData 'csgo', 'wins', wins, defer whatever

				if playerCheckQueue.length > 0
					setTimeout () =>
						CSGO.playerProfileRequest CSGO.ToAccountID playerCheckQueue.pop()
					, 2000
				else
					CSGO.removeAllListeners()
					CSGO.exit()

		CSGO.on 'unready', =>
			CSGO.removeAllListeners()

Mikuia.Events.on 'twitch.updated', =>
	if not twitchDone
		plugin = Mikuia.Plugin.getPlugin 'steam'

		GC = new steam.SteamGameCoordinator plugin.bot, 730
		CSGO = new csgo.CSGOClient plugin.user, GC, false

		launchAndUpdate()

		setInterval () =>
			launchAndUpdate()
		, 10 * 60 * 1000

		twitchDone = true

Mikuia.Events.on 'csgo.stats', (data) =>
	Channel = new Mikuia.Models.Channel data.to

	await
		Channel.getPluginData 'csgo', defer err, pluginData

	if not err
		rankId = 0
		wins = 0

		if pluginData?.rank? then rankId = parseInt pluginData.rank
		if pluginData?.wins? then wins = parseInt pluginData.wins

		if rankId >= 0 and rankId <= 18
			message = Mikuia.Format.parse data.settings.format,
				{rankId, rankName: rankNames[rankId], wins}

			if data.settings._whisper
				Mikuia.Chat.whisper data.user.username, message
			else
				Mikuia.Chat.say Channel.getName(), message 