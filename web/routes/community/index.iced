module.exports = (req, res) ->
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

	await Mikuia.Element.preparePanels 'community.index', defer panels

	sortLeaderboard = new Mikuia.Models.Leaderboard 'viewers'

	await Mikuia.Streams.getAllSorted 'viewers', defer sorting, streams
	await sortLeaderboard.getDisplayHtml defer err, displayHtml

	res.render 'community/index',
		featured: featuredStream
		panels: panels
		sorting: sorting
		streams: streams
		displayHtml: displayHtml