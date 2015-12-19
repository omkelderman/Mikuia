fs = require 'fs'
request = require 'request'
_ = require 'underscore'

class exports.Tools
	constructor: (@Mikuia) ->

	chunkArray: (array, size) ->
		R = []
		if !array.length then return R
		for i in [0..array.length] by size
			R.push array.slice i, i + size
		return R

	colorRarity: (rarity) ->
		switch rarity
			when 'common'
				'<span style="color: white;">Common</span>'
			when 'uncommon'
				'<span style="color: #1eff00;">Uncommon</span>'
			when 'rare'
				'<span style="color: #338BFF;">Rare</span>'
			when 'epic'
				'<span style="color: #B356F0;">Epic</span>'
			when 'legendary'
				'<span style="color: #FF9933;">Legendary</span>'
			when 'unique'
				'<span style="color: #e6cc80;">Unique</span>'
			else
				'<span style="color: red;">UNKNOWN</span>'

	fillArray: (data, size) ->
		array = []
		data = _.shuffle data.slice 0
		while array.length < size
			array.push data[Math.round(Math.random() * data.length)]
		return array

	getAvatars: (limit) ->
		files = fs.readdirSync 'web/public/img/avatars'
		return @fillArray files, limit

	getExperience: (level) ->
		if level > 0
			return (((level * 20) * level * 0.8) + level * 100) - 16
		else
			return 0

	getLevel: (experience) ->
		level = 0
		while experience >= @getExperience level
			level++

		return level - 1

	getLevelProgress: (experience) =>
		level = @getLevel experience
		currentExp = experience - @getExperience(level)
		nextLevelExp = @getExperience(level + 1) - @getExperience(level)

		return Math.floor((currentExp / nextLevelExp) * 100)
