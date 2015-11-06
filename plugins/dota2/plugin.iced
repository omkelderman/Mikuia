dota2 = require 'dota2'
steam = require 'steam'

Dota2 = null
GC = null
plugin = null
twitchDone = false

launchAndUpdate = =>
	#woop

Mikuia.Events.on 'twitch.updated', =>
	if not twitchDone
		plugin = Mikuia.Plugin.getPlugin 'steam'

		Dota2 = new dota2.Dota2Client plugin.bot, true

		launchAndUpdate()

		setInterval () =>
			launchAndUpdate()
		, 10 * 60 * 1000

		twitchDone = true