import * as cli from 'cli-color';
import * as zmq from 'zmq';

import {Log} from './log';
import {Services} from './services';
import {Settings} from './settings';
import {Tools} from './tools';

export class Messaging {
    private handlers = {};
    private plugins: string[] = [];
    private tokens = {};

    private pub: zmq.Socket;
    private rep: zmq.Socket;

    constructor(private services: Services, private settings: Settings)  {
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

            case "identify":
                var name = req.args.name;

                if(name && this.plugins.indexOf(name) == -1) {
                    this.plugins.push(name);
                    
                    var token = Math.random().toString(36).slice(-32);
                    this.tokens[token] = name;

                    return this.reply(req, {
                        type: 'string',
                        error: false,
                        message: token
                    })
                }

                return this.reply(req, {
                    error: true
                });

            case "registerHandler":
                var name = req.args.name;

                if(!this.handlers[name] && this.tokens[req.token]) {
                    this.handlers[name] = {
                        plugin: this.tokens[req.token],
                        info: req.args.info
                    }

                    return this.reply(req, {
                        error: false
                    });
                }

                return this.reply(req, {
                    error: true
                });
            
            case "respond":
                if(this.tokens[req.token]) {
                    var event = req.args.event;
                    var data = req.args.data;

                    var service = this.services.get(event.service.type);
                    if(service) {
                        service.handleResponse(event, data);

                        return this.reply(req, {
                            error: false
                        })
                    }
                }

                return this.reply(req, {
                    error: true
                })

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