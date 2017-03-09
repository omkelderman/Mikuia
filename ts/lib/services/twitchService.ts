import * as cli from 'cli-color';
import * as limiter from 'rolling-rate-limiter';
import * as redis from 'redis';
import * as request from 'request';
import * as tmi from 'tmi.js';

import {Channel} from '../channel';
import {Log} from '../log';
import {MikuiaService} from './mikuiaService';
import {Mikuia} from '../../mikuia';
import {Models} from '../models';
import {Settings} from '../settings'
import {Tools} from '../tools';

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

	constructor(private settings: Settings, private db: redis.RedisClient, private models: Models) {}

	async connect() {
		for(let id of [...Array(this.settings.services.twitch.connections).keys()]) {
			this.connections[id] = await this.spawnConnection(id); 
		}
	}

	getChannel(name: string) {
		return this.models.getChannel(name, 'twitch');
	}

	async join(channel: Channel) {
		if(channel.type == 'twitch') {
			if(!(channel.id in this.channelsJoined)) {
				var limitEntries = await this.db.zrangebyscoreAsync('service:twitch:limiter:join', '-inf', '+inf');
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
							this.connections[0].join(channel.name).catch((err) => {
								Log.error('Twitch', 'Failed to join channel: #' + channel.name + '.');
								console.log(err);
							})
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
					debug: false
				},
				connection: {
					reconnect: true
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
				Log.error('Twitch', logHeader + ' Disconnected.');
				console.log(reason);
			})

			client.on('join', (channel: string, username: string) => {
				if(username == this.settings.services.twitch.username.toLowerCase()) {
					Log.info('Twitch', logHeader + ' Joined channel: ' + channel + '.');
				}
			})

			client.on('message', (channel: string, userstate: any, message: string, self: boolean) => {
				if(message.toLowerCase().indexOf('lukanya') > -1) {
					Log.info('Twitch', logHeader + ' ' + cli.yellowBright(channel) + ' / ' + cli.greenBright(userstate.username) + ': ' + message);
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
			console.log(cli.magenta(chunk.join(',')));
			request({
				url: 'https://api.twitch.tv/kraken/streams/?channel=' + chunk.join(',') + '&client_id=' + this.settings.services.twitch.clientId + '&api_version=5'
			}, (err, res, body) => {
				if(!err) {
					resolve(JSON.parse(body));
				} else {
					console.log(err);
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
				var data: any = await this.parseChunk(chunk);

				for(let stream of data.streams) {
					var channel = this.getChannel(stream.channel.name);
					this.join(channel);
				}
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