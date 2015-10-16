dropChance = Mikuia.settings.plugins.items.dropChance
dropCooldown = Mikuia.settings.plugins.items.dropCooldown
dropList = Mikuia.settings.plugins.items.dropList

dropCooldowns = {}
isMikuia = (Mikuia.settings.bot.name == 'Mikuia')

if isMikuia
	Mikuia.Events.on 'twitch.message', (user, to, message) =>
		if !dropCooldowns[user.username]? or (dropCooldowns[user.username] + (dropCooldown * 1000)) < (new Date()).getTime()
			if Math.random() < dropChance 
				Viewer = new Mikuia.Models.Channel user.username
				await Viewer.getTotalLevel defer err, totalLevel
				if totalLevel > 40
					itemId = dropList[Math.floor(Math.random() * dropList.length)]
					Mikuia.Items.createItem itemId, Viewer.getName()
					Mikuia.Chat.whisper Viewer.getName(), 'You have obtained an item: "' + Mikuia.Items.getItemSchema().items[itemId].name + '"! Check out your inventory on http://mikuia.tv/user/' + Viewer.getName() + '/inventory'
			dropCooldowns[user.username] = (new Date()).getTime()