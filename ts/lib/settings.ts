export interface Settings {
	redis: {
		port: number,
		host: string,
		db: number,
		options: any
	},
	services: {
		twitch: {
			username: string,
			oauth: string
		}
	}
}
