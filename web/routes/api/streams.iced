module.exports =
	featured: (req, res) ->
		await Mikuia.Streams.getAllSorted Mikuia.settings.web.featureMethod, defer sorting, streams

		if sorting.length > 0
			stream = sorting[0][0]
		else
			await Mikuia.Streams.getAllSorted Mikuia.settings.web.featureFallbackMethod, defer sorting, streams
			if sorting.length > 0
				stream = sorting[0][0]
			else
				stream = null

		featuredStream = null
		if stream
			Channel = new Mikuia.Models.Channel stream
			await
				Mikuia.Streams.get stream, defer err, featuredStream
				Channel.getBio defer err, bio
				Channel.isSupporter defer err, isSupporter

			if featuredStream?
				featuredStream.bio = bio
				featuredStream.name = featuredStream.display_name

				if isSupporter
					featuredStream.display_name = '❤ ' + featuredStream.display_name
					
		res.json
			featured: featuredStream

	list: (req, res) ->
		# game = ''

		# if !req.param 'sortMethod'
		# 	sortMethod = 'viewers'
		# else
		# 	sortMethod = req.param 'sortMethod'

		# sortLeaderboard = new Mikuia.Models.Leaderboard sortMethod

		# await Mikuia.Streams.getAllSorted sortMethod, defer sorting, streams
		# await sortLeaderboard.getDisplayHtml defer err, displayHtml

		# leaderboards = {}
		# lbList = Mikuia.Element.getAll 'leaderboards'
		# for lbName in lbList
		# 	lb = new Mikuia.Models.Leaderboard lbName
		# 	await lb.getDisplayName defer err, displayName
		# 	leaderboards[lbName] = displayName

		# res.render 'community/streams',
		# 	titlePath: ['Streams']
		# 	displayHtml: displayHtml
		# 	leaderboards: leaderboards
		# 	sorting: sorting
		# 	sortMethod: sortMethod
		# 	streams: streams

		await Mikuia.Database.smembers 'mikuia:streams', defer err, streams

		limit = 0
		offset = 0

		if req.param 'limit'
			limit = parseInt req.param 'limit'

		if req.param 'offset'
			offset = parseInt req.param 'offset'

		streamList = []

		if limit != 0
			for i in [offset..offset + limit - 1]
				if streams[i]?
					streamList.push streams[i]
		else
			streamList = streams


		if not err
			res.json
				streams: streamList
				total: streams.length
				limit: limit
				offset: offset
		else
			res.json
				error: true