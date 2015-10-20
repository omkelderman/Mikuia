module.exports =
	plugins: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username
		plugins = Mikuia.Plugin.getAll()

		await
			Channel.isEnabled defer err, enabled
			Channel.getEnabledPlugins defer err, enabledPlugins

		categories = {}
		settings = {}
		for pluginName in enabledPlugins
			await Channel.getSettings pluginName, defer err, settings[pluginName]

			categories[pluginName] = {}
			manifest = Mikuia.Plugin.getManifest pluginName
			if manifest?.settings?.channel?
				for settingName, setting of manifest.settings.channel
					if setting.category?
						if !categories[pluginName][setting.category]?
							categories[pluginName][setting.category] = {}
						categories[pluginName][setting.category][settingName] = setting

		res.render 'dashboard/plugins',
			enabled: enabled
			enabledPlugins: enabledPlugins
			plugins: plugins
			settings: settings

	pluginToggle: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username
		data = req.body

		if data.status? && data.name?
			switch data.status
				when "enable"
					depsMet = true
					manifest = Mikuia.Plugin.getManifest data.name
					missingPlugins = []

					if manifest?.dependencies?	
						await Channel.getEnabledPlugins defer err, enabledPlugins

						for plugin in manifest.dependencies
							if plugin not in enabledPlugins
								depsMet = false
								missingPlugins.push plugin

					if depsMet
						await Channel.enablePlugin data.name, defer err, data
						res.send
							enabled: true
					else
						res.send
							enabled: false
							reason: 'This plugin requires: ' + missingPlugins.join(',') + '.' 

				when "disable"
					await Channel.getEnabledPlugins defer err, enabledPlugins

					pluginRequired = false
					requiredBy = []

					for plugin in enabledPlugins
						manifest = Mikuia.Plugin.getManifest plugin

						if manifest?.dependencies?
							if data.name in manifest.dependencies
								pluginRequired = true
								requiredBy.push plugin

					if not pluginRequired
						await Channel.disablePlugin data.name, defer err, data
						res.send
							enabled: false
					else
						res.send
							enabled: true
							reason: 'This plugin is required by: ' + requiredBy.join(',') + '.'
		else
			res.send 500