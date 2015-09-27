fs = require 'fs-extra'
moment = require 'moment'
_ = require 'underscore'

module.exports =
	run: (args) =>
		source = args[0]
		target = args[1]

		Source = new Mikuia.Models.Channel source
		Target = new Mikuia.Models.Channel target

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
		
		console.log 'Found ' + experience.length + ' user levels.'
		console.log 'Found ' + Object.keys(levels).length + ' channel levels.'

		if args[2]? and args[2] == 'confirm'

			console.log 'Handling channel levels...'

			for levelSeqId, levelData of levels

				username = levelData[0]
				xpAmount = parseInt levelData[1]
				Viewer = new Mikuia.Models.Channel username

				console.log 'Adding ' + xpAmount + ' of ' + Target.getName() + ' XP to ' + username + '...'
				
				await Viewer.addExperience Target.getName(), xpAmount, 100, defer whatever

				console.log 'Resetting ' + username + '\'s ' + Source.getName() + ' XP to 0...'

				await Viewer.addExperience Source.getName(), xpAmount * -1, 100, defer whatever

			console.log 'Handling user levels...'

			for userLevelData in experience

				username = userLevelData[0]
				xpAmount = parseInt userLevelData[1]

				console.log 'Adding ' + xpAmount + ' of ' + username + ' XP to ' + Target.getName() + '...'

				await Target.addExperience username, xpAmount, 100, defer whatever

				console.log 'Resetting ' + xpAmount + ' of ' + username + ' XP to 0 for ' + Source.getName() + '...'

				await Source.addExperience username, xpAmount * -1, 100, defer whatever

		process.exit 1