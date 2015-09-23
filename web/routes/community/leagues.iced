module.exports =
	index: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username

		await
			Mikuia.Leagues.getFightCount Channel.getName(), defer err, fightCount
			Mikuia.Leagues.getFightCountLost Channel.getName(), defer err, fightsLost
			Mikuia.Leagues.getFightCountWon Channel.getName(), defer err, fightsWon
			Mikuia.Leagues.getRating Channel.getName(), defer err, rating
		
		res.render 'community/leagues',
			fightCount: fightCount
			fightsLost: fightsLost
			fightsWon: fightsWon
			rating: rating

	leaderboards: (req, res) ->
		await Mikuia.Database.zrevrange 'leaderboard:1v1rating:scores', 0, 99, 'withscores', defer err, ranks
		
		channels = Mikuia.Tools.chunkArray ranks, 2
		displayNames = {}
		fights = {}
		isStreamer = {}
		logos = {}

		for data in channels
			if data.length > 0
				channel = new Mikuia.Models.Channel data[0]
				rating = data[1]

				await
					channel.isStreamer defer err, isStreamer[data[0]]
					channel.getDisplayName defer err, displayNames[data[0]]
					channel.getLogo defer err, logos[data[0]]
					Mikuia.Leagues.getFightCount channel.getName(), defer err, fights[data[0]]

		res.render 'community/leagueLeaderboards',
			channels: channels
			displayNames: displayNames
			fights: fights
			isStreamer: isStreamer
			logos: logos
