csgo = require 'csgo'
steam = require 'steam'

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

launchAndUpdate = =>
	plugin = Mikuia.Plugin.getPlugin 'steam'

	GC = new steam.SteamGameCoordinator plugin.bot, 730
	CSGO = new csgo.CSGOClient plugin.user, GC, false

	# LOL
	CSGO.launch()

	CSGO.on 'ready', =>
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

		if playerCheckQueue.length > 0
			CSGO.playerProfileRequest CSGO.ToAccountID playerCheckQueue.pop()
		else
			CSGO.exit()

		CSGO.on 'playerProfile', (playerProfile) =>
			if playerProfile?.account_profiles?[0]?
				profile = playerProfile.account_profiles[0]

				await Mikuia.Database.hget 'plugin:steam:users', CSGO.ToSteamID(profile.account_id), defer err, channel

				if not err and channel
					Channel = new Mikuia.Models.Channel channel

					rank = ""
					wins = ""

					if profile.ranking?.rank_id? then rank = profile.ranking.rank_id
					if profile.ranking?.wins? then wins = profile.ranking.wins

					await
						Mikuia.Database.hset 'channel:' + Channel.getName() + ':plugin:csgo:settings', 'rank', rank, defer whatever
						Mikuia.Database.hset 'channel:' + Channel.getName() + ':plugin:csgo:settings', 'wins', wins, defer whatever

			if playerCheckQueue.length > 0
				setTimeout () =>
					CSGO.playerProfileRequest CSGO.ToAccountID playerCheckQueue.pop()
				, 2000
			else
				CSGO.exit()

Mikuia.Events.on 'steam.connected', =>
	launchAndUpdate()

	setInterval () =>
		launchAndUpdate()
	, 10 * 60 * 1000

Mikuia.Events.on 'csgo.stats', (data) =>
	Channel = new Mikuia.Models.Channel data.to

	await Channel.getSettings 'csgo', defer err, settings
	if not err
		rank_id = parseInt settings.rank
		wins = parseInt settings.wins

		if rank_id >= 0 and rank_id <= 18
			message = Mikuia.Format.parse data.settings.format,
				rank_id: rank_id
				rank_name: rankNames[rank_id]
				wins: wins

			if data.settings._whisper
				Mikuia.Chat.whisper data.user.username, message
			else
				Mikuia.Chat.say Channel.getName(), message 