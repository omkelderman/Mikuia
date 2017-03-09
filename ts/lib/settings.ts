import * as redis from 'redis';

export interface Settings {
	redis: {
		port: number,
		host: string,
		db: number,
		options: redis.ClientOpts
	},
	services: {
		twitch: {
			username: string,
			oauth: string,
			connections: number,
			clientId: string
		}
	}
}