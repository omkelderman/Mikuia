dota2 = require 'dota2'
steam = require 'steam'

Dota2 = null
GC = null
plugin = null
twitchDone = false

# launchAndUpdate = =>
# 	Dota2.launch()

# 	Dota2.on 'ready', =>
# 		accountId = 9710254
# 		#await Dota2.requestProfile accountId, true, defer err, response
# 		await Dota2.requestProfileCard accountId, defer err, response

# 		console.log err
# 		console.log response

# 		Dota2.exit()

Mikuia.Events.on 'twitch.updated', =>
	if not twitchDone
		plugin = Mikuia.Plugin.getPlugin 'steam'

		Dota2 = new dota2.Dota2Client plugin.bot, true

		# launchAndUpdate()

		# setInterval () =>
		# 	launchAndUpdate()
		# , 10 * 60 * 1000

		twitchDone = true