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

	await Mikuia.Database.hgetall 'plugin:steam:users', defer err, steamUsers

	for steamId, steamUser of plugin.friends.personaStates
		if steamUser.gameid == '730' and steamId of steamUsers
			Channel = new Mikuia.Models.Channel steamUsers[steamId]

			await Channel.isPluginEnabled 'csgo', defer err, enabled
			if enabled then playerCheckQueue.push steamId

	if plugin.bot.loggedOn and playerCheckQueue.length > 0
		CSGO.launch()

		CSGO.on 'ready', =>
			CSGO.playerProfileRequest CSGO.ToAccountID playerCheckQueue.pop()

			CSGO.on 'playerProfile', (playerProfile) =>
				if playerProfile?.account_profiles?[0]?
					profile = playerProfile.account_profiles[0]
					
					if not err and steamUsers[profile.account_id]?
						Channel = new Mikuia.Models.Channel steamUsers[profile.account_id]

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

			Mikuia.Chat.handleResponse data.user.username, Channel.getName(), message, data.settings._target, data.details