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

import {TwitchGetLiveStreamsResponse} from '../responses/twitchGetLiveStreamsResponse';

export class TwitchService implements MikuiaService {
	private channelsJoined: Array<string> = [];
	private connectionChannels = {};
	private connections = {};
	private idMappings = {};
	private nextJoinClient = 0;

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
		return new Promise(async (resolve) => {
			if(channel.type == 'twitch') {
				if(this.channelsJoined.indexOf('#' + channel.name) == -1) {
					/*	Uhhh, I think this deserves an explanation.
						I don't have one.
						This has been working for like a year or so, it's probably fine. */

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

								if(this.nextJoinClient >= this.settings.services.twitch.connections) {
									this.nextJoinClient = 0;
								}

								this.connections[this.nextJoinClient].join(channel.name).then(() => {
									resolve();
								}).catch((err) => {
									Log.error('Twitch', 'Failed to join channel: ' + cli.yellowBright('#' + channel.name) + '.');
									console.log(err);
									resolve(err);
								})
							} else {
								resolve(true);
							}
						})
					} else {
						resolve(true);
					}
				} else {
					resolve(true);
				}
			} else {
				resolve(true);
			}
		});
	}

	spawnConnection(id: number) {
		var self = this;
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

			this.connectionChannels[client.id] = [];

			client.on('connected', (address: string, port: number) => {
				Log.info('Twitch', logHeader + ' Connected to ' + cli.yellowBright(address + ':' + port) + '.');
				resolve(client);
			})

			client.on('disconnected', (reason: string) => {
				Log.error('Twitch', logHeader + ' Disconnected.');
				console.log(reason);

				// TODO: clear this.connectionChannels & join the channels back
			})

			client.on('join', (channel: string, username: string) => {
				if(username == this.settings.services.twitch.username.toLowerCase()) {
					Log.info('Twitch', logHeader + ' Joined channel: ' + cli.yellowBright(channel) + '.');

					this.channelsJoined.push(channel);
					this.connectionChannels[client.id].push(channel);
					this.nextJoinClient++;
				}
			})

			client.on('message', (channel: string, userstate: any, message: string, self: boolean) => {
				if(message.toLowerCase().indexOf(this.settings.services.twitch.username.toLowerCase()) > -1) {
					Log.info('Twitch', logHeader + ' ' + cli.yellowBright(channel) + ' ' + cli.yellow('(' + this.idMappings[channel] + ')') + ' / ' + cli.greenBright(userstate.username) + ': ' + message);
				}
			})

			client.on('part', (channel, username) => {
				if(username == this.settings.services.twitch.username.toLowerCase()) {
					Log.info('Twitch', logHeader + ' Left channel: ' + channel + '.');

					this.channelsJoined.splice(this.channelsJoined.indexOf(channel), 1);
					this.connectionChannels[client.id].splice(this.connectionChannels[client.id].indexOf(channel), 1);
				}
			})
		})
	}

	async start() {
		this.updateChannels();
		setInterval(() => {
			this.updateChannels()
		}, 2000);
	}

	async parseChunk(chunk): Promise<TwitchGetLiveStreamsResponse> {
		return new Promise<TwitchGetLiveStreamsResponse>((resolve) => {
			request({
				url: 'https://api.twitch.tv/kraken/streams/?channel=' + chunk.join(',') + '&client_id=' + this.settings.services.twitch.clientId + '&api_version=5'
			}, (err, res, body) => {
				if(!err) {
					resolve(JSON.parse(body));
				} else {
					Log.error('Twitch', 'Channel check request failed. Resolving with an empty array.');
					console.log(err);
					resolve({
						_total: 0,
						streams: []
					});
				}
			})
		})
	}

	async updateChannels() {
		if(!this.updatingChannels) {
			// This is so fucking ugly, I know.
			Log.info('Twitch', 'Starting the channel check.');
			this.updatingChannels = true;

			var channels = await this.db.smembersAsync('service:twitch:channels:enabled');

			for(let [index, chunk] of Tools.chunkArray(channels, 100).entries()) {
				// Fucking lmao
				Log.info('Twitch', 'Checking channels ' + (index * 100 + 1) + ' to ' + (index * 100 + chunk.length) + '...')

				var data: TwitchGetLiveStreamsResponse = await this.parseChunk(chunk);
				for(let stream of data.streams) {
					var channel = this.getChannel(stream.channel.name);
					
					await this.join(channel);
					
					this.idMappings['#' + stream.channel.name] = stream.channel._id;
				}
			}

			Log.info('Twitch', 'Finished the channel check.');
			this.updatingChannels = false;
		}
	}

}