import * as bluebird from 'bluebird';
import * as cli from 'cli-color';
import * as redis from 'redis';
import * as request from 'request';

bluebird.promisifyAll(redis);

declare module 'redis' {
	export interface RedisClient extends NodeJS.EventEmitter {
		hsetAsync(...args: any[]): Promise<any>;
		saddAsync(...args: any[]): Promise<any>;
		smembersAsync(...args: any[]): Promise<any>;
	}
}

function chunkArray(array: Array<any>, size: number): Array<any> {
	var R: Array<any> = [];
	var a = array.slice(0);
	while(a.length > 0) {
		R.push(a.splice(0, size));
	}
	return R;
}

class Migration {
	private settings = require('../settings.json');

	private miku = redis.createClient(this.settings.redis.port, this.settings.redis.host, this.settings.redis.options);
	private luka = this.miku.duplicate();

	async continue() {
		var channelsEnabled = await this.miku.smembersAsync('mikuia:channels');

		for(let chunk of chunkArray(channelsEnabled, 100)) {
			var res = await this.getIDsForUsernames(chunk);
		
			for(let user of res.users) {
				await this.parseUser(user);
			}
		}
	}

	async getIDsForUsernames(usernames): Promise<any> {
		return new Promise((resolve, reject) => {
			request('https://api.twitch.tv/kraken/users?api_version=5&client_id=' + this.settings.services.twitch.clientId + '&login=' + usernames.join(','), (err, res, body) => {
				if(!err) {
					var data = JSON.parse(body);
					resolve(data);
				} else {
					console.log(err);
					reject(err);	
				}
			});
		})
	}

	async parseUser(user) {
		console.log('Parsing user ' + cli.redBright(user.name + ' (' + user.display_name + ')') + ' with ID ' + cli.yellowBright(user._id));
		await this.luka.saddAsync('service:twitch:channels:enabled', user._id);
		await this.luka.hsetAsync('service:twitch:ids:usernames', user._id, user.name);
		await this.luka.hsetAsync('service:twitch:usernames:ids', user.name, user._id);
		await this.luka.hsetAsync('channel:twitch:' + user._id, 'display_name', user.display_name);
		await this.luka.hsetAsync('channel:twitch:' + user._id, 'name', user.username);
	}

	start() {
		this.miku.on('ready', () => {
			this.miku.select(1);
			console.log('miku ready');
			this.luka = this.miku.duplicate();
		})

		this.luka.on('ready', () => {
			this.luka.select(14);
			console.log('luka ready');

			setTimeout(() => {
				this.continue()
			}, 1000);
		})
	}
}

var migration = new Migration();
migration.start();