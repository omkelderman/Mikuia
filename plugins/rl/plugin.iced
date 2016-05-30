cli = require 'cli-color'
request = require 'request'
rls = require 'rls-api'

client = new rls.Client
	token: Mikuia.settings.plugins.rl.token

tierNames = [
	'Unranked'
	'Prospect I'
	'Prospect II'
	'Prospect III'
	'Prospect Elite'
	'Challenger I'
	'Challenger II'
	'Challenger III'
	'Challenger Elite'
	'Rising Star'
	'Shooting Star'
	'All-Star'
	'Superstar'
	'Champion'
	'Super Champion'
	'Grand Champion'
]

divisionNames = [
	''
	'I'
	'II'
	'III'
	'IV'
	'V'
]

playlistNames = {
	'10': 'duel'
	'11': 'doubles'
	'12': 'soloStandard'
	'13': 'standard'
}

Mikuia.Events.on 'rl.player', (data) =>
	Channel = new Mikuia.Models.Channel data.to
	await
		Channel.getDisplayName defer err, displayName
		Channel.isPluginEnabled 'rl', defer err2, enabled

	if not err2 and enabled
		await
			Channel.getSetting 'rl', 'platform', defer err, platform
			Channel.getSetting 'rl', 'name', defer err, name

		await client.getPlayer name, parseInt(platform), defer status, player
		if status == 200
			if player.rankedSeasons[data.settings.season]?
				console.log player
				console.log player.rankedSeasons['1']

				stats = player.stats

				for playlistId, playlistName of playlistNames
					if player.rankedSeasons[data.settings.season][playlistId].rankPoints?
						stats[playlistName + 'RankPoints'] = player.rankedSeasons[data.settings.season][playlistId].rankPoints
						if data.settings.season == '2'
							stats[playlistName + 'Matches'] = player.rankedSeasons[data.settings.season][playlistId].matchesPlayed
							stats[playlistName + 'Tier'] = player.rankedSeasons[data.settings.season][playlistId].tier
							stats[playlistName + 'Division'] = player.rankedSeasons[data.settings.season][playlistId].division
							stats[playlistName + 'TierName'] = tierNames[player.rankedSeasons[data.settings.season][playlistId].tier]
							stats[playlistName + 'DivisionName'] = divisionNames[player.rankedSeasons[data.settings.season][playlistId].division]
					else
						player.rankedSeasons[data.settings.season][playlistId].rankPoints = 0

				message = Mikuia.Format.parse data.settings.format, stats
				Mikuia.Chat.handleResponse data.user.username, Channel.getName(), message, data.settings._target, data.details
		else
			console.log 'fail'