import {Settings} from './lib/settings';

export class Mikuia {
	private settings: Settings;

	loadSettings() {
		try {
			this.settings = require('./settings.json');
		} catch(error) {
			throw new Error('Failed to load the config file.');
		}
	}

	start() {
		this.loadSettings();
	}
}