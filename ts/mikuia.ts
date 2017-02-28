import * as redis from 'redis';

import {Log} from './lib/log';
import {Settings} from './lib/settings';
import {TwitchChat} from './lib/services/twitchChat'

export class Mikuia {
	private db: redis.RedisClient;
	private twitchChat: TwitchChat;

	public settings: Settings;

	initDatabase() {
		this.db = redis.createClient(this.settings.redis.port, this.settings.redis.host, this.settings.redis.options);

		this.db.on('ready', () => {
			Log.success('Redis', 'Connected to Redis.')
			this.db.select(this.settings.redis.db);
		})

		this.db.on('error', (error) => {
			Log.fatal('Redis', 'Something broke.')
			console.log(error);
		})
	}

	loadSettings() {
		try {
			this.settings = require('./settings.json');
		} catch(error) {
			throw new Error('Failed to load the config file.');
		}
	}

	start() {
		this.loadSettings();
		this.initDatabase();

		this.twitchChat = new TwitchChat(this);
		this.twitchChat.connect();
	}
}