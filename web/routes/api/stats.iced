module.exports =
	userLevels: (req, res) =>
		if req.params.username?
			Channel = new Mikuia.Models.Channel req.params.username

			await Channel.exists defer err, exists
			if !err and exists
				await
					Channel.getTotalExperience defer err, totalExperience
					Channel.getTotalLevel defer err, totalLevel
					Mikuia.Database.zrevrank 'mikuia:experience', Channel.getName(), defer err, totalRank

				res.json
					experience: parseInt totalExperience
					level: parseInt totalLevel
					rank: parseInt(totalRank) + 1
			else
				res.send 404
		else
			res.send 400