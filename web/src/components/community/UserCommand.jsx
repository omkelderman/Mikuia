import React from 'react'
import $ from 'jquery'

import {OverlayTrigger, Tooltip} from 'react-bootstrap'
import {LinkContainer} from 'react-router-bootstrap'

var UserCommand = React.createClass({
	render: function() {
		return (
			<div className="mikuia-card mikuia-profile-command">
				<div className="mikuia-card-block mikuia-card-block-margin">
					<OverlayTrigger placement="top" overlay={
						<Tooltip>{this.props.data.pluginName}</Tooltip>
					}>
						<img src={"/img/plugins/" + this.props.data.plugin + ".png"} width="24" height="24" />
					</OverlayTrigger>
					
				</div>
				<div className="mikuia-card-block">
					<h4>
						{this.props.data.name}
						<If condition={this.props.data.settings}>

							<If condition={this.props.data.settings._minLevel && this.props.data.settings._minLevel > 0}>
								<OverlayTrigger placement="top" overlay={
									<Tooltip>
										<b>Level {this.props.data.settings._minLevel}</b>
										<br />
										This command requires Level {this.props.data.settings._minLevel}.
									</Tooltip>
								}>
									<span className="text-danger">
										<i className="fa fa-star" />
										<small className="text-danger">  {this.props.data.settings._minLevel}</small>
									</span>
								</OverlayTrigger>
							</If>

							<If condition={this.props.data.settings._cooldown && this.props.data.settings._cooldown > 2}>
								<OverlayTrigger placement="top" overlay={
									<Tooltip>
										<b>{this.props.data.settings._cooldown}s Cooldown</b>
										<br />
										This command is usable every {this.props.data.settings._cooldown} second(s).
									</Tooltip>
								}>
									<span className="text-danger">
										<i className="fa fa-refresh" />
										<small className="text-danger">  {this.props.data.settings._cooldown}s</small>
									</span>
								</OverlayTrigger>
							</If>

							<If condition={this.props.data.settings._coinCost && this.props.data.settings._coinCost > 0}>
								<Choose>
									<When condition={this.props.data.settings._coinCost > 1}>
										<OverlayTrigger placement="top" overlay={
											<Tooltip>
												<b>{this.props.data.settings._coinCost} {this.props.data.coin.coinNamePlural}</b>
												<br />
												This command costs {this.props.data.settings._coinCost} {this.props.data.coin.coinNamePlural}.
											</Tooltip>
										}>
											<span className="text-warning">
												<i className="fa fa-money" />
												<small className="text-warning">  {this.props.data.settings._coinCost}</small>
											</span>
										</OverlayTrigger>
									</When>
									<Otherwise>
										<OverlayTrigger placement="top" overlay={
											<Tooltip>
												<b>{this.props.data.settings._coinCost} {this.props.data.coin.coinName}</b>
												<br />
												This command costs {this.props.data.settings._coinCost} {this.props.data.coin.coinName}.
											</Tooltip>
										}>
											<span className="text-warning">
												<i className="fa fa-money" />
												<small className="text-warning">  {this.props.data.settings._coinCost}</small>
											</span>
										</OverlayTrigger>
									</Otherwise>
								</Choose>
							</If>


							<If condition={this.props.data.settings._onlyMods}>
								<OverlayTrigger placement="top" overlay={
									<Tooltip>
										<b>Only Mods</b>
										<br />
										This command is usable only by moderators.
									</Tooltip>
								}>
									<i className="text-success fa fa-user-plus" />
								</OverlayTrigger>
							</If>

							<If condition={this.props.data.settings._onlySubs}>
								<OverlayTrigger placement="top" overlay={
									<Tooltip>
										<b>Only Subs</b>
										<br />
										This command is usable only by subscribers.
									</Tooltip>
								}>
									<i className="text-info fa fa-twitch" />
								</OverlayTrigger>
							</If>

							<If condition={this.props.data.settings._onlyBroadcaster}>
								<OverlayTrigger placement="top" overlay={
									<Tooltip>
										<b>Only Broadcaster</b>
										<br />
										This command is usable only by the streamer.
									</Tooltip>
								}>
									<i className="text-primary fa fa-video-camera" />
								</OverlayTrigger>
							</If>

							<If condition={this.props.data.settings._whisper}>
								<OverlayTrigger placement="top" overlay={
									<Tooltip>
										<b>Whisper Response</b>
										<br />
										The reponse to this command will be whispered.
									</Tooltip>
								}>
									<i className="text-info fa fa-comment" />
								</OverlayTrigger>
							</If>

						</If>
					</h4>
					<If condition={this.props.data.codeText}>
						<pre>
							<code>{this.props.data.description}</code>
						</pre>
					</If>
					<If condition={!this.props.data.codeText}>
						<span>{this.props.data.description}</span>
					</If>
				</div>
			</div>
		)
	}

})

export default UserCommand

