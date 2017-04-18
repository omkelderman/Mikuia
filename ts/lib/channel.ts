import * as redis from 'redis';

export class Channel {
	public id: number;
	public type: string;

	constructor(id: number, type: string, private db: redis.RedisClient) {
		this.id = id;
		this.type = type;
	}

	async getCommand(trigger: string): Promise<string | null> {
		var handler = await this.db.hgetAsync('channel:' + this.type + ':' + this.id + ':commands', trigger);
		return handler;
	}

	async getName(): Promise<string> {
		return await this.db.hgetAsync('channel:' + this.type + ':' + this.id, 'username');
	}

}