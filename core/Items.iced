Schema = require '../items/schema'
_ = require 'underscore'

defaultItem:
	description: "Unknown Description"
	name: "Unknown Item"
	rarity: "default"

class exports.Items
	constructor: (@Mikuia) ->

	changeOwner: (instanceId, ownerName) =>
		await Mikuia.Database.hget 'mikuia:items:owners', instanceId, defer err, oldOwnerName
		newOwner = new Mikuia.Models.Channel ownerName
		
		if oldOwnerName?
			oldOwner = new Mikuia.Models.Channel oldOwnerName
			await Mikuia.Database.srem 'channel:' + oldOwner.getName() + ':items', instanceId, defer whatever

		await
			Mikuia.Database.sadd 'channel:' + newOwner.getName() + ':items', instanceId, defer whatever
			Mikuia.Database.hset 'mikuia:items:owners', instanceId, newOwner.getName(), defer whatever

	createItem: (itemId, ownerName) =>
		await @getHighestInstanceId defer err, highestInstanceId
		newId = highestInstanceId + 1

		await
			Mikuia.Database.hset 'item:' + newId, 'itemId', itemId, defer whatever
			Mikuia.Database.set 'mikuia:items:highestId', newId, defer whatever
		if ownerName?
			@changeOwner newId, ownerName

	getHighestInstanceId: (callback) =>
		await Mikuia.Database.get 'mikuia:items:highestId', defer err, highestId
		callback err, parseInt highestId

	getItem: (instanceId, callback) =>
		await Mikuia.Database.hgetall 'item:' + instanceId, defer err, item
		item.instanceId = instanceId

		if not err and item?.itemId?
			if Schema.items[item.itemId]?
				callback err, _.extend({}, item, Schema.items[item.itemId])
			else
				callback err, _.extend({}, item, defaultItem)
		else
			callback err, {}

	getItemSchema: => Schema

	getUserInventory: (username, callback) =>
		items = []
		await @getUserItems username, defer err, itemIds
		for itemId in itemIds
			await @getItem itemId, defer err, item
			if not err
				items.push item
		callback false, items

	getUserItems: (username, callback) =>
		Channel = new Mikuia.Models.Channel username
		Mikuia.Database.smembers 'channel:' + Channel.getName() + ':items', callback

	