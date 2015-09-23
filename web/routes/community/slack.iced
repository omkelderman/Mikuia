module.exports =
	index: (req, res) ->
		totalLevel = 0

		if req.isAuthenticated()
			Channel = new Mikuia.Models.Channel req.user.username
			await Channel.getTotalLevel defer err, totalLevel

		res.render 'community/slack',
			totalLevel: totalLevel

	invite: (req, res) ->
		totalLevel = 0

		if req.isAuthenticated()
			Channel = new Mikuia.Models.Channel req.user.username
			await Channel.getTotalLevel defer err, totalLevel

			if req.user.email? and totalLevel >= 10
				Mikuia.Tools.inviteToSlack req.user.email, req.user.displayName

				res.render 'community/slackInvite'
			else
				res.render 'community/error',
					error: 'Something went wrong...'
		else
			res.render 'community/error',
				error: 'You are not logged in.'
