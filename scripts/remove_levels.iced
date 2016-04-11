fs = require 'fs-extra'
moment = require 'moment'
_ = require 'underscore'

module.exports =
	run: (args) =>
		source = args[0]

		Source = new Mikuia.Models.Channel source

		await fs.copy '/home/hatsune/redis/dump.rdb', '/home/hatsune/redis/backups/dump-' + moment().format('YY-MM-DD-HH-mm-ss') + '.rdb', defer err
		if not err
			console.log 'copied.'
		else
			console.log 'failed to copy.'
			process.exit 1

		await
			Source.getAllExperience defer err, experience
			Mikuia.Database.zrevrange 'levels:' + Source.getName() + ':experience', 0, -1, 'withscores', defer err, rawLevels

		levels = _.groupBy rawLevels, (a, b) => Math.floor b / 2

		if args[1]? and args[1] == 'confirm'
			console.log 'Handling user levels...'

			for userLevelData in experience
				username = userLevelData[0]
				xpAmount = parseInt userLevelData[1]

				console.log 'Resetting ' + xpAmount + ' of ' + username + ' XP to 0 for ' + Source.getName() + '...'

				await Source.addExperience username, xpAmount * -1, 100, defer whatever

		process.exit 1
