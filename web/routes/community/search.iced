elasticsearch = require 'elasticsearch'

if Mikuia.settings.elasticsearch.enable
	es = new elasticsearch.Client
		host: Mikuia.settings.elasticsearch.host
		log: 'warning'

module.exports = (req, res) =>
	if not Mikuia.settings.elasticsearch.enable
		res.send JSON.stringify ['disabled']
	else if req.body.type? and req.body.query?
		switch req.body.type
			when 'username-completion'
				await es.suggest
					index: 'users'
					body:
						suggestions:
							text: req.body.query
							completion:
								field: 'suggest'
								size: 5
				, defer err, response

				if err
					console.log err
					res.send JSON.stringify ['err']
				else
					suggestions = []
					for option in response.suggestions[0].options
						suggestions.push option.text

					res.send JSON.stringify suggestions
					console.log suggestions
			else
				res.send JSON.stringify ['switch']
	else
		res.send JSON.stringify ['fail']
