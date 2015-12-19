module.exports =
	csgo: (req, res) ->
		res.render 'community/guides/csgo',
			titlePath: ['Guides', 'CS:GO Rank']

	levels: (req, res) ->
		res.render 'community/guides/levels',
			titlePath: ['Guides', 'Mikuia Levels']

	osu: (req, res) ->
		res.render 'community/guides/osu',
			titlePath: ['Guides', 'osu! Requests']

	quickstart: (req, res) ->
		res.render 'community/guides/quickstart',
			titlePath: ['Guides', 'Quick Start Guide']
