declare module 'redis' {
	export interface RedisClient extends NodeJS.EventEmitter {
		lpopAsync(...args: any[]): Promise<string>;
		rpushAsync(...args: any[]): Promise<string>;
		smembersAsync(...args: any[]): Promise<Array<string>>;
		zrangebyscoreAsync(...args: any[]): Promise<Array<string>>;
	}
}