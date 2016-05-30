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

console.log Mikuia.settings.plugins.rl.token

Mikuia.Events.on 'rl.player', (data) =>
	Channel = new Mikuia.Models.Channel data.to
	await
		Channel.getDisplayName defer err, displayName
		Channel.isPluginEnabled 'rl', defer err2, enabled

	if not err2 and enabled
		await
			Channel.getSetting 'rl', 'platform', defer err, platform
			Channel.getSetting 'rl', 'name', defer err, name
			Channel.getSetting 'rl', 'season', defer err, season

		console.log platform
		console.log name

		await client.getPlayer name, parseInt(platform), defer status, player
		if status == 200
			if player.rankedSeasons[season]?
				console.log player
				console.log player.rankedSeasons['1']

				stats = player.stats

				for playlistId, playlistName of playlistNames
					if player.rankedSeasons[season][playlistId].rankPoints?
						stats[playlistName + 'RankPoints'] = player.rankedSeasons[season][playlistId].rankPoints
						if season == '2'
							stats[playlistName + 'Matches'] = player.rankedSeasons[season][playlistId].matchesPlayed
							stats[playlistName + 'Tier'] = player.rankedSeasons[season][playlistId].tier
							stats[playlistName + 'Division'] = player.rankedSeasons[season][playlistId].division
							stats[playlistName + 'TierName'] = tierNames[player.rankedSeasons[season][playlistId].tier]
							stats[playlistName + 'DivisionName'] = divisionNames[player.rankedSeasons[season][playlistId].division]

				message = Mikuia.Format.parse data.settings.format,
					wins: stats.wins
					goals: stats.goals
					mvps: stats.mvps
					saves: stats.saves
					shots: stats.shots
					assists: stats.assists

				Mikuia.Chat.handleResponse data.user.username, Channel.getName(), message, data.settings._target, data.details
		else
			console.log 'fail'