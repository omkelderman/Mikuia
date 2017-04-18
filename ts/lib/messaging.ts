import * as cli from 'cli-color';
import * as zmq from 'zmq';

import {Log} from './log';
import {Settings} from './settings';
import {Tools} from './tools';

export class Messaging {
    private pub: zmq.Socket;
    private rep: zmq.Socket;

    constructor(private settings: Settings)  {
        this.pub = zmq.socket('pub');
        this.rep = zmq.socket('rep');

        this.pub.bindSync(this.settings.zeromq.address + ':' + this.settings.zeromq.ports[0]);

        this.rep.bindSync(this.settings.zeromq.address + ':' + this.settings.zeromq.ports[1]);
        this.rep.on('message', (message) => {
            Log.info('0mq', 'Received a message: ' + cli.greenBright(message));
            this.parseMessage(JSON.parse(message.toString()));
        })

        Log.info('0mq', 'REP listening on: ' + cli.redBright(this.settings.zeromq.address + ':' + this.settings.zeromq.ports[0]));
        Log.info('0mq', 'PUB listening on: ' + cli.redBright(this.settings.zeromq.address + ':' + this.settings.zeromq.ports[1]));
    }

    broadcast(topic: string, message: object) {
        this.pub.send([topic, JSON.stringify(message)]);
    }

    parseMessage(req) {
        switch(req.method) {
            case "getExample":
                return this.reply(req, {
                    type: 'string',
                    message: 'test123',
                    error: false
                });
            default:
                console.log('the fuck.');
                return this.reply(req, {
                    error: true
                });
        }
    }

    reply(req, res) {
        this.rep.send(JSON.stringify(Tools.extend(req, res)));
    }

}