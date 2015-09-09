countdown = require 'countdown'
moment = require 'moment'
mathjs = require 'mathjs'
_ = require 'underscore'

countdown.setLabels	'ms|s|m|h|d|w|mo|y|dc|ct|ml',
	'ms|s|m|h|d|w|mo|y|dc|ct|ml',
	' ',
	' ',
	'',
	(n) -> n.toString()

helperFunctions =

	# Math
	ceil: (variable) -> Math.ceil variable
	commas: (variable) ->
		# http://stackoverflow.com/questions/2901102/how-to-print-a-number-with-commas-as-thousands-separators-in-javascript
		parts = variable.toString().split '.'
		parts[0] = parts[0].replace /\B(?=(\d{3})+(?!\d))/g, ','
		parts.join '.'
	floor: (variable) -> Math.floor variable
	round: (variable, decimals) -> 
		if decimals?
			Math.round(variable * Math.pow(10, decimals)) / Math.pow(10, decimals)
		else Math.round variable
	round1: (variable) -> Math.round(variable * 10) / 10
	round2: (variable) -> Math.round(variable * 100) / 100
	round3: (variable) -> Math.round(variable * 1000) / 1000
	round4: (variable) -> Math.round(variable * 10000) / 10000

	# Strings
	lower: (string) -> string.toString().toLowerCase()
	upper: (string) -> string.toString().toUpperCase()

	# Dates and stuff
	countdown: (string) -> countdown(new Date(string)).toString()
	timeago: (string) -> moment(string).fromNow()

class exports.Format
	parse: (format, data) ->
		re = /<%([^%>]+)?%>/g

		matches = []
		while match = re.exec format
			matches.push match

		for match in matches
			if data[match[1]]?
				format = format.replace match[0], data[match[1]]
			else if match[1].indexOf('/') > -1
				tokens = match[1].split '/'
				if data[tokens[tokens.length - 1]]?
					variable = data[tokens[tokens.length - 1]]
					tokens.splice tokens.length - 1, 1
					for token in tokens
						if token in helperFunctions
							variable = helperFunctions[token] variable

					format = format.replace match[0], variable
				else
					format = format.replace match[0], '!undefined!'
			else
				format = format.replace match[0], ''

		return @parseNew format, data

	parseNew: (format, data) ->
		math = mathjs.create()
		math.import (_.extend data, helperFunctions), { override: true }
		format.replace /{{([^}}]+)}}/g, (match, p) ->
			math.eval p
