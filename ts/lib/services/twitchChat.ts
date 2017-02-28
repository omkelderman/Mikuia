import * as cli from 'cli-color';
import * as tmi from 'tmi.js';

import {Log} from '../log';
import {MikuiaService} from './mikuiaService';
import {Mikuia} from '../../mikuia';

export class TwitchChat implements MikuiaService {
    private connections = {};
    private mikuia: Mikuia;

    constructor(mikuia: Mikuia) {
        this.mikuia = mikuia;
    }

    async connect() {
        var connectionCount = 5;

        for(let id of [...Array(connectionCount - 1).keys()]) {
            this.connections[id] = await this.spawnConnection(id, 'main'); 
        }
    }

    spawnConnection(id: number, type: string) {
        return new Promise((resolve) => {
            var client = new tmi.client({
                options: {
                    debug: true
                },
                connection: {
                    cluster: type,
                    reconnect: false
                },
                identity: {
                    username: this.mikuia.settings.services.twitch.username,
                    password: this.mikuia.settings.services.twitch.oauth
                }
            })

            if(id != null) {
                client.id = id;
            }

            client.connect();

            client.on('connected', (address: string, port: number) => {
                Log.info('Twitch', 'Connected to ' + cli.yellowBright(address + ':' + port) + '.');

                setTimeout(() => {
                    resolve(client);
                }, 500);
            })

            client.on('disconnected', (reason: string) => {
                Log.error('Twitch', 'Disconnected. Reason: ' + reason);
            })

            client.on('join', (channel: string, username: string) => {
                if(username == this.mikuia.settings.services.twitch.username.toLowerCase()) {
                    Log.info('Twitch', 'Joined channel: ' + channel + '.');
                }
            })

            client.on('part', (channel, username) => {
                if(username == this.mikuia.settings.services.twitch.username.toLowerCase()) {
                    Log.info('Twitch', 'Left channel: ' + channel + '.');
                }
            })
        })
    }

}