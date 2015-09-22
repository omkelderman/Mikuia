moment = require 'moment'
parseIsoDuration = require 'parse-iso-duration'
request = require 'request'

require 'moment-duration-format'

queueItem = (item, Channel, data, callback) =>
	await Mikuia.Database.zrevrangebyscore 'channel:' + Channel.getName() + ':autodj:list', '+inf', '-inf', 'withscores', defer error, list

	nextId = 1
	if list.length >= 2
		nextId = parseInt(list[1]) + 1

	await Mikuia.Database.zadd 'channel:' + Channel.getName() + ':autodj:list', nextId, JSON.stringify(item), defer whatever
	message = '#' + nextId + ': ' + item.title + ' (' + item.duration + ') added to the list.' 
	if data.settings._whisper
		Mikuia.Chat.whisper data.user.username, message
	else
		Mikuia.Chat.say data.to, message

requestSoundCloudTrackData = (scLink, callback) =>
	await request 'http://api.soundcloud.com/resolve?url=' + scLink + '&client_id=' + @Plugin.getSetting('scId'), defer error, response, body
	if not error and response.statusCode == 200
		callback false, JSON.parse(body)
	else
		callback true, {}

requestYouTubeVideoData = (videoId, callback) =>
	await request 'https://www.googleapis.com/youtube/v3/videos?part=contentDetails,snippet,statistics&id=' + videoId + '&key=' + @Plugin.getSetting('ytApiKey'), defer error, response, body
	if not error and response.statusCode == 200
		callback false, JSON.parse(body).items[0]
	else
		callback true, {}

Mikuia.Events.on 'adj.request', (data) ->
	Channel = new Mikuia.Models.Channel data.to

	# Credit to jrom
	# http://stackoverflow.com/questions/3717115/regular-expression-for-youtube-links
	ytMatch = /(?:www\.)?youtu(?:be\.com\/watch\?v=|\.be\/)([\w\-]+)(&(amp;)?[\w\?=]*)?/g.exec data.message
	if ytMatch? and ytMatch.length > 2
		potentialYouTubeId = ytMatch[1]

		await requestYouTubeVideoData potentialYouTubeId, defer error, yt
		if not error and yt?.snippet?
			item =
				type: 'youtube'
				id: potentialYouTubeId
				requester: data.user.username
				thumbnail: yt.snippet.thumbnails.default.url
				title: yt.snippet.title
				duration: moment.duration(parseIsoDuration(yt.contentDetails.duration) / 1000, 'seconds').format()
				plays: yt.statistics.viewCount
				likes: yt.statistics.likeCount
				dislikes: yt.statistics.dislikeCount
				comments: yt.statistics.commentCount
				url: 'http://youtu.be/' + potentialYouTubeId

			await queueItem item, Channel, data, defer whatever

	else
		scMatch = /https?:\/\/(soundcloud.com|snd.sc)\/(.*)$/g.exec data.message
		if scMatch? and scMatch.length > 2
			potentialScLink = scMatch[0]

			await requestSoundCloudTrackData potentialScLink, defer error, sc
			if not error and sc?.duration?
				item =
					type: 'soundcloud'
					id: sc.id
					requester: data.user.username
					thumbnail: sc.artwork_url
					title: sc.title
					duration: moment.duration(sc.duration / 1000, 'seconds').format()
					plays: sc.playback_count
					likes: sc.favoritings_count
					dislikes: 0
					comments: sc.comment_count
					url: potentialScLink

				await queueItem item, Channel, data, defer whatever