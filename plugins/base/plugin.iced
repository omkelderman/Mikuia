channelCooldown = {}

addDummy = (username, channel, tokens, target, details) =>
	Channel = new Mikuia.Models.Channel channel

	if tokens.length == 1 || tokens.length == 2
		Mikuia.Chat.handleResponse username, channel, 'You failed.', target
	else if tokens.length > 2
		command = tokens[1]
		message = ''
		text = tokens.slice(2, tokens.length).join ' '

		await
			Channel.addCommand command, 'base.dummy', defer err, data
			Channel.setCommandSetting command, 'message', text, defer err2, data

		if not err and not err2
			message = 'Command "' + command + '" probably added.'
		else
			message = 'Um, something failed. Oops.'

		Mikuia.Chat.handleResponse username, channel, message, target, details

removeCommand = (username, channel, tokens, target, details) =>
	Channel = new Mikuia.Models.Channel channel

	if tokens.length == 1 || tokens.length > 2
		Mikuia.Chat.handleResponse username, channel, 'Fail.', target
	else if tokens.length == 2
		command = tokens[1]
		message = ''

		await Channel.removeCommand command, defer err, data

		if not err
			message = 'Command "' + command + '" probably removed.'
		else
			message = 'I probably screwed something up... oh well.'

		Mikuia.Chat.handleResponse username, channel, message, target, details
			
Mikuia.Events.on 'base.add.dummy', (data) =>
	addDummy data.user.username, data.to, data.tokens, data.settings._target, data.details

Mikuia.Events.on 'base.dummy', (data) =>
	args = data.tokens.slice(1, data.tokens.length).join ' '

	Channel = new Mikuia.Models.Channel data.to
	await
		Channel.getSetting 'base', 'dummyCustomFormat', defer err, dummyCustomFormat
		Channel.getSetting 'base', 'dummyCustomMessage', defer err, dummyCustomMessage

	if user?
		Viewer = new Mikuia.Models.Channel data.user.username
		await Viewer.getDisplayName defer err, viewerDisplayName
	else
		viewerDisplayName = '<Anonymous>'

	dummyMessage = Mikuia.Format.parse data.settings.message,
		args: args
		color: data.user.color
		displayName: viewerDisplayName
		message: data.message
		username: data.user.username

	if data.settings._target == 'twitch'
		if dummyCustomFormat
			dummyMessage = Mikuia.Format.parse dummyCustomMessage,
				args: args
				color: data.user.color
				displayName: viewerDisplayName
				dummyMessage: dummyMessage
				message: data.message
				username: data.user.username

	Mikuia.Chat.handleResponse data.user.username, data.to, dummyMessage, data.settings._target, data.details

Mikuia.Events.on 'base.levels', (data) =>
	Channel = new Mikuia.Models.Channel data.user.username
	if Channel.getName() != data.to.replace('#', '')
		await
			Channel.getDisplayName defer err, displayName
			Channel.getExperience data.to.replace('#', ''), defer err2, experience
			Mikuia.Database.zrevrank 'levels:' + data.to.replace('#', '') + ':experience', data.user.username, defer err3, rank

		if !experience
			experience = 0

		level = Mikuia.Tools.getLevel experience
		message = displayName + ': #' + (rank + 1) + ' - Lv ' + level + ' (' + experience + ' / ' + Mikuia.Tools.getExperience(level + 1) + ' XP)'

		Mikuia.Chat.handleResponse data.user.username, data.to, message, data.settings._target, data.details

Mikuia.Events.on 'base.remove', (data) =>
	removeCommand data.user.username, data.to, data.tokens, data.settings._target, data.details

Mikuia.Events.on 'base.uptime', (data) =>
	Channel = new Mikuia.Models.Channel data.to
	await Channel.isLive defer err, isLive

	message = ''

	if isLive
		await Mikuia.Streams.get Channel.getName(), defer err, stream
		if !err && stream?
			startTime = (new Date(stream.created_at)).getTime() / 1000
			endTime = Math.floor((new Date()).getTime() / 1000)

			totalTime = endTime - startTime

			seconds = totalTime % 60
			minutes = ((totalTime - seconds) / 60) % 60
			hours = ((totalTime - seconds) - (60 * minutes)) / 3600

			if minutes < 10
				minutes = '0' + minutes

			if seconds < 10
				seconds = '0' + seconds

			message = 'Uptime: ' + hours + 'h ' + minutes + 'm ' + seconds + 's'
		else
			message = 'Something went wrong, try again!'
	else
		message =  'The stream is not live.'

	Mikuia.Chat.handleResponse data.user.username, data.to, message, data.settings._target, data.details

Mikuia.Events.on 'mikuia.message', (from, to, message, target, details) =>
	globalCommand = @Plugin.getSetting 'globalCommand'
	username = if from? then from.username else null

	if message.indexOf(globalCommand) == 0
		Channel = new Mikuia.Models.Channel to
		canContinue = true

		if channelCooldown[Channel.getName()]?
			if channelCooldown[Channel.getName()] + 5000 > (new Date()).getTime()
				canContinue = false

		if canContinue
			channelCooldown[Channel.getName()] = (new Date()).getTime()

			if message.trim() == globalCommand
				Mikuia.Chat.handleResponse username, to, 'Hey, I\'m Mikuia, and I\'m a bot made by Hatsuney! Learn more about me at http://mikuia.tv', target, details
			else
				tokens = message.trim().split ' '
				trigger = tokens[1]

				if from?
					User = new Mikuia.Models.Channel from.username
					isAdmin = User.isAdmin()
					isMod = checkMod to, from.username
				else
					isAdmin = false
					isMod = false

				if isAdmin
					isMod = true
					
				switch trigger
					when 'commands'
						Mikuia.Chat.handleResponse username, to, 'Commands for this channel: http://mikuia.tv/user/' + Channel.getName(), target, details

					when 'dummy'
						if isMod
							addDummy username, to, tokens.slice(1), target

					when 'emit'
						if isAdmin
							type = tokens[2]
							switch type
								when 'handler'
									handler = tokens[3]
									if tokens.length > 4
										dataRaw = tokens[4]

									data =
										user: from.username
										to: to
										message: ''
										tokens: []
										settings: {}

									if dataRaw?

										if dataRaw.indexOf('{') == 0
											try
												jsonData = JSON.parse dataRaw
											catch error
												if error
													Mikuia.Log.error error

											if jsonData?
												for key, value of jsonData
													data[key] = value
										else
											for value in dataRaw.split(';')
												args = value.split '='
												data[args[0]] = args[1]

									console.log data
									Mikuia.Events.emit handler, data

								else
									# nope for now ;P

					when 'levels'
						Mikuia.Chat.handleResponse username, to, 'Levels for this channel: http://mikuia.tv/levels/' + Channel.getName(), target, details

					when 'mods'
						if isMod
							moderators = Mikuia.Chat.mods to
							if moderators?
								Mikuia.Chat.handleResponse from.username, to, 'This is what I know:' + JSON.stringify(moderators), target, details

					when 'rating'
						if from?
							await
								Mikuia.Leagues.getFightCount User.getName(), defer err, fights
								Mikuia.Leagues.getRating User.getName(), defer err, rating
								User.getDisplayName defer err, displayName

							if fights < 10
								Mikuia.Chat.handleResponse from.username, to, displayName + ' > Unranked (' + fights + ' fights, ' + rating + ' elo)', target, details
							else
								Mikuia.Chat.handleResponse from.username, to, displayName + ' > ' + Mikuia.Leagues.getLeagueFullText(rating) + ' (' + fights + ' fights, ' + rating + ' elo)', target, details

					when 'remove'
						if isMod
							removeCommand from.username, to, tokens.slice(1), target

					when 'say'
						if isAdmin
							Mikuia.Chat.sayUnfiltered to, tokens.slice(2).join(' ')

					when 'status'
						Mikuia.Chat.handleResponse username, to, 'Current Mikuia status: https://p.datadoghq.com/sb/AF-ona-ccd2288b29', target, details
					else
						# do nothing

checkMod = (channel, username) ->
	if !username?
		return false
		
	if channel == '#' + username
		return true
	else
		moderators = Mikuia.Chat.mods channel
		if moderators? && username in moderators
			return true
		else
			return false