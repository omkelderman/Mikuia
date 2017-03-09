import * as redis from 'redis';

export class Models {

    constructor(private db: redis.RedisClient) {}
    
    getChannel(name: string, type: string) {
        return {
            id: 0,
            name: name,
            type: type
        }
    }

}