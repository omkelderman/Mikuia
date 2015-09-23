module.exports = (req, res) ->
	if req.params.userId?
		Channel = new Mikuia.Models.Channel req.params.userId

		await Channel.exists defer err, exists
		if !err 
			if exists
				await Channel.getDisplayName defer err, displayName
				await Channel.getProfileBanner defer err, profileBanner
				await Mikuia.Database.zrevrange 'levels:' + Channel.getName() + ':experience', 0, 99, 'withscores', defer err, ranks

				channels = Mikuia.Tools.chunkArray ranks, 2
				displayNames = {}
				experience = null
				isStreamer = {}
				logos = {}
				rank = null

				for data in channels
					if data.length > 0
						channel = new Mikuia.Models.Channel data[0]
						experience = data[1]

						await
							channel.isStreamer defer err, isStreamer[data[0]]
							channel.getDisplayName defer err, displayNames[data[0]]
							channel.getLogo defer err, logos[data[0]]

				if req.isAuthenticated()
					channel = new Mikuia.Models.Channel req.user.username
					await
						channel.getExperience Channel.getName(), defer err, experience
						Mikuia.Database.zrevrank 'levels:' + Channel.getName() + ':experience', req.user.username, defer err, rank

				res.render 'community/levelsUser',
					channels: channels
					displayName: displayName
					displayNames: displayNames
					experience: experience
					isStreamer: isStreamer
					logos: logos
					profileBanner: profileBanner
					rank: rank + 1
			else
				res.render 'community/error',
					error: 'Channel does not exist.'
		else
			res.render 'community/error',
				error: err

	else
		await Mikuia.Streams.getAll defer err, streams

		displayNames = {}
		experience = {}
		logos = {}
		ranks = {}
		totalLevel = null
		userCount = {}

		if req.isAuthenticated()
			Channel = new Mikuia.Models.Channel req.user.username

			await
				Channel.getAllExperience defer err, data
				Channel.getTotalLevel defer err, totalLevel	

			for md in data
				experience[md[0]] = md[1]

				chan = new Mikuia.Models.Channel md[0]
				await chan.getDisplayName defer err, displayNames[md[0]]

			for stream in streams
				await Mikuia.Database.zrevrank 'levels:' + stream + ':experience', req.user.username, defer err, ranks[stream]

			for name, rank of ranks
				ranks[name]++

		for stream in streams
			chan = new Mikuia.Models.Channel stream
			await chan.getDisplayName defer err, displayNames[stream]
			await Mikuia.Database.zcard 'levels:' + stream + ':experience', defer err, userCount[stream]

		await Mikuia.Database.zrevrange 'mikuia:experience', 0, 4, 'withscores', defer err, totalLevels
		mexp = Mikuia.Tools.chunkArray totalLevels, 2

		mlvl = []
		for md in mexp
			if md.length > 0
				chan = new Mikuia.Models.Channel md[0]
				await
					chan.getDisplayName defer err, displayNames[md[0]]
					chan.getLogo defer err, logos[md[0]]
				mlvl.push [
					md[0]
					Mikuia.Tools.getLevel md[1]
				]

		res.render 'community/levels',
			displayNames: displayNames
			experience: experience
			level: totalLevel
			logos: logos
			mlvl: mlvl
			ranks: ranks
			rawExperience: data
			streams: streams
			userCount: userCount