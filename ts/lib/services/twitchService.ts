import * as cli from 'cli-color';
import * as limiter from 'rolling-rate-limiter';
import * as redis from 'redis';
import * as request from 'request';
import * as tmi from 'tmi.js';

import {Channel} from '../channel';
import {Log} from '../log';
import {MikuiaService} from './mikuiaService';
import {Mikuia} from '../../mikuia';
import {Settings} from '../settings'
import {Tools} from '../tools';

declare module 'redis' {
	export interface RedisClient extends NodeJS.EventEmitter {
		smembersAsync(...args: any[]): Promise<any>;
		zrangebyscoreAsync(...args: any[]): Promise<any>;
	}
}

export class TwitchService implements MikuiaService {
	private channelsJoined = [];
	private connections = {};

	private joinLimiter = limiter({
		interval: 10 * 1000,
		maxInInterval: 49,
		namespace: 'service:twitch:limiter:join',
		redis: this.db
	})

	private updatingChannels = false;

	constructor(private settings: Settings, private db: redis.RedisClient) {}

	async connect() {
		for(let id of [...Array(this.settings.services.twitch.connections).keys()]) {
			this.connections[id] = await this.spawnConnection(id); 
		}
	}

	join(channel: Channel) {
		if(channel.type == 'twitch') {
			if(!(channel.id in this.channelsJoined)) {
				var limitEntries: any = this.db.zrangebyscoreAsync('service:twitch:limiter:join', '-inf', '+inf');
				var currentTime = (new Date).getTime() * 1000;
				var remainingRequests = 49;

				for(let limitEntry of limitEntries) {
					if(parseInt(limitEntry) + 15 * 1000 * 1000 > currentTime) {
						remainingRequests--;
					}
				}

				if(remainingRequests > 0) {
					this.joinLimiter('', (err, timeLeft) => {
						if(!timeLeft) {
							this.connections[0].join(channel.name);
						}
					})
				}
			}
		}
	}

	spawnConnection(id: number) {
		return new Promise((resolve) => {
			var logHeader = '[' + cli.cyanBright(id) + ']';

			var client = new tmi.client({
				options: {
					clientId: this.settings.services.twitch.clientId,
					debug: true
				},
				connection: {
					reconnect: false
				},
				identity: {
					username: this.settings.services.twitch.username,
					password: this.settings.services.twitch.oauth
				}
			})

			client.id = id;
			client.connect();

			client.on('connected', (address: string, port: number) => {
				Log.info('Twitch', logHeader + ' Connected to ' + cli.yellowBright(address + ':' + port) + '.');
				resolve(client);
			})

			client.on('disconnected', (reason: string) => {
				Log.error('Twitch', logHeader + ' Disconnected. Reason: ' + reason);
			})

			client.on('join', (channel: string, username: string) => {
				if(username == this.settings.services.twitch.username.toLowerCase()) {
					Log.info('Twitch', logHeader + ' Joined channel: ' + channel + '.');
				}
			})

			client.on('part', (channel, username) => {
				if(username == this.settings.services.twitch.username.toLowerCase()) {
					Log.info('Twitch', logHeader + ' Left channel: ' + channel + '.');
				}
			})
		})
	}

	async start() {
		await this.updateChannels();
		setInterval(() => {
			this.updateChannels()
		}, 2000);
	}

	async parseChunk(chunk) {
		return new Promise((resolve, reject) => {
			request({
				url: 'https://api.twitch.tv/kraken/streams/?channel=' + chunk.join(',') + '&client_id=' + this.settings.services.twitch.clientId + '&api_version=5'
			}, (err, res, body) => {
				if(!err) {
					resolve(JSON.parse(body));
				} else {
					reject(err);
				}
			})
		})
	}

	async updateChannels() {
		if(!this.updatingChannels) {
			this.updatingChannels = true;
			var channels = await this.db.smembersAsync('service:twitch:channels:enabled');

			for(let chunk of Tools.chunkArray(channels, 100)) {
				var streams = await this.parseChunk(chunk);
				console.log(streams);
			}

			// this.updatingChannels = false;
		}

		// this.db.smembers('channels:enabled', (err, data) => {
		// 	console.log(err);
		// 	console.log(data);
		// });

		// this.twitchChat.join(this.models.getChannel('esl_csgo', 'twitch'));
	}

}