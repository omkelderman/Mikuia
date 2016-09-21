import React from 'react'
import {LinkContainer} from 'react-router-bootstrap'
import {Button, Col, Row} from 'react-bootstrap'

var Home = React.createClass({

	componentDidMount: function() {
		var self = this
		this.props.resetHeaderOptions(function() {
			self.props.setHeaderOption('extended', false)
			self.props.setHeaderOption('splash', true)
		})
	},

	componentWillUnmount: function() {
		this.props.resetHeaderOptions()
	},

	render: function() {
		return (
			<div className="container text-white">
				<br />
				<div className="mikuia-index">
					<Row>
						<Col md={5} className="align-center mikuia-index-screenshot" />
						<Col md={5} mdOffset={1}>
							<h1>Mikuia <small>is a Twitch bot.</small></h1>
							<p className="text-muted">
								Mikuia helps your viewers interact with games you're playing.
								<br />
								Looking up stats, sharing accomplishments and useful information, providing level and coin systems!
							</p>
							<br />
							<LinkContainer to="/guides/quickstart">
								<Button bsStyle="default">Quick Start Guide</Button>
							</LinkContainer>

						</Col>
					</Row>
				</div>
			</div>
		)
	},

})

export default Home