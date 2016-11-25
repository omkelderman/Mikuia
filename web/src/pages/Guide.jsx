import React from 'react'

import {Alert, Col, Grid, Row} from 'react-bootstrap'
import {translate} from 'react-i18next'

var Guide = React.createClass({

	componentDidMount: function() {
		this.props.setHeaderOption('title', [this.props.t('header:link.guide')])
	},

	render: function() {
		const {t} = this.props
		return (
			<div>
				<Grid>
					<Row>
						<Col md={12}>
							<h1>The Guide</h1>
							<Alert bsStyle="danger">
								<strong>I swear to God.</strong> No matter how simple to follow the guide is, you people <b>still</b> manage to get completely lost.<br />
								If you can't understand what is happening, read it again. And again. Ask a friend to help you understand it. Call your mom. Cry a lot.<br />
								Make sure there's absolutely nothing more you can do before you start asking for help.
							</Alert>

							<h2>Table of Contents</h2>
							<br />
							<a href="#guide-what">What's Mikuia?</a>
							<br />
							<a href="#guide-how">How to enable Mikuia?</a>
							<br />
							<a href="#guide-commands">How to add commands?</a>
							<br />
							<a href="#guide-games">Where can I find game specific features?</a>
							<br />
							<a href="#guide-no">Why is Mikuia not working?</a>
							<br />


							<hr />


							<div id="guide-what">
								<h1>What's Mikuia?</h1>
								<p>Mikuia is a Twitch bot.</p>
							</div>

							<div id="guide-how">
								<h1>How to enable Mikuia?</h1>
								<p>
									<ol>
										<li>
											Login using the "Login with Twitch" button in the top right corner.
										</li>
										<li>
											Click "Dashboard" in the top right corner.
										</li>
										<li>
											Click "Settings".
										</li>
										<li>
											Click "Enable".
										</li>
									</ol>
								</p>
							</div>

							<div id="guide-commands">
								<h1>How to add commands?</h1>
								<p>
									<ol>
										<li>
											Open the "Dashboard".
										</li>
										<li>
											Click "Commands".
										</li>
										<li>
											Click "Add a command".
										</li>
										<li>
											Follow the pop-up.
										</li>
									</ol>
								</p>
							</div>

							<div id="guide-games">
								<h1>Where can I find game specific features?</h1>
								<p>
									<ol>
										<li>
											Open the "Dashboard".
										</li>
										<li>
											Click "Plugins".
										</li>
										<li>
											Find a game you care about and click "Enable".
										</li>
										<li>
											Click "Settings" next to the button you just clicked.
										</li>
									</ol>
								</p>
							</div>

							<div id="guide-no">
								<h1>Why is Mikuia not working?</h1>
								<p>
									99% of the time, it's your fault. Triple check the settings.
									<br />
									Mikuia joins your channel after a short period of time from you going live.
								</p>
							</div>

							<hr />

							This guide is short because I honestly don't give a fuck.
							<br />
							If you need more help, try asking on <a href="http://discord.mikuia.tv">Discord</a>, or use the live chat (violet bubble in bottom right corner).

						</Col>
					</Row>
				</Grid>
			</div>
		)
	}

})

export default translate('guide', {wait: true})(Guide)