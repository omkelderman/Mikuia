import * as bluebird from 'bluebird';
import * as redis from 'redis';

bluebird.promisifyAll(redis);

import {Log} from './lib/log';	
import {Messaging} from './lib/messaging';
import {Models} from './lib/models';
import {Settings} from './lib/settings';
import {TwitchService} from './lib/services/twitchService'

export class Mikuia {
	private db: redis.RedisClient;
	private msg: Messaging;
	private models: Models;
	private settings: Settings;
	private twitchService: TwitchService;

	async initDatabase() {
		return new Promise((resolve) => {
			this.db = redis.createClient(this.settings.redis.port, this.settings.redis.host, this.settings.redis.options);

			this.db.on('ready', () => {
				Log.success('Redis', 'Connected to Redis.')
				this.db.select(this.settings.redis.db);
				resolve();
			})

			this.db.on('error', (error) => {
				Log.fatal('Redis', 'Something broke.')
				console.log(error);
			})
		})
	}

	initModels() {
		this.models = new Models(this.db);
	}

	loadSettings() {
		try {
			this.settings = require('./settings.json');
		} catch(error) {
			throw new Error('Failed to load the config file.');
		}
	}

	async start() {
		this.loadSettings();
		
		await this.initDatabase();
		this.initModels();

		this.msg = new Messaging(this.settings);

		this.twitchService = new TwitchService(this.settings, this.db, this.models, this.msg);
		await this.twitchService.connect();
		this.twitchService.start();
	}
}