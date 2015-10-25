module.exports = 
	csgo: (req, res) ->
		res.render 'community/guides/csgo'

	levels: (req, res) ->
		res.render 'community/guides/levels'

	osu: (req, res) ->
		res.render 'community/guides/osu'

	quickstart: (req, res) ->
		res.render 'community/guides/quickstart'