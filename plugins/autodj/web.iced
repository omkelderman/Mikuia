_ = require 'underscore'

Mikuia.Element.register 'dashboardPagePlugin',
	plugin: 'autodj'
	pages:
		'/':
			name: 'Auto DJ'
			icon: 'fa fa-music'

checkAuth = (req, res, next) ->
	if req.isAuthenticated()
		return next()
	res.redirect '/login'

Mikuia.Web.get '/dashboard/plugins/autodj', checkAuth, (req, res) =>
	res.render '../../plugins/autodj/views/index'

Mikuia.Web.get '/dashboard/plugins/autodj/list', checkAuth, (req, res) =>
	Channel = new Mikuia.Models.Channel req.user.username

	await Mikuia.Database.zrangebyscore 'channel:' + Channel.getName() + ':autodj:list', '-inf', '+inf', 'withscores', defer error, list

	if list?
		requests = _.groupBy list, (a, b) => Math.floor b / 2

		queue = []
		for objectId, object of requests
			data = JSON.parse object[0]
			data.requestId = object[1]
			queue.push data
			
		res.send JSON.stringify queue
	else
		res.send JSON.stringify []

Mikuia.Web.post '/dashboard/plugins/autodj/remove', checkAuth, (req, res) =>
	if req.body.requestId?
		Channel = new Mikuia.Models.Channel req.user.username
		
		await Mikuia.Database.zremrangebyscore 'channel:' + Channel.getName() + ':autodj:list', req.body.requestId, req.body.requestId, defer whatever

		res.send 200
	else
		res.send 500