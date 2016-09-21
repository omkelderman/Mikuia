import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'
import {Button, Col, Grid, OverlayTrigger, Row, Tooltip} from 'react-bootstrap'

import Card from '../components/community/Card'
import CardBlock from '../components/community/CardBlock'
import CardBlockUser from '../components/community/CardBlockUser'

var Levels = React.createClass({

	componentDidMount: function() {
		this.poll()
	},

	getInitialState: function() {
		return {
			channels: [],
			error: false,
			loading: true
		}
	},

	poll: function() {
		var self = this
		self.setState({
			loading: true
		})
		$.get('/api/levels').success(function(data) {
			self.setState({
				channels: data.channels,
				loading: false
			})
		}).fail(function() {
			self.setState({
				error: true,
				loading: false,
				channels: []
			})
		})
	},

	render: function() {
		return (
			<div>
				<Grid>
					<Row>
						<Col md={9}>

							<h1 className="mikuia-page-header-text">
								Random Channels

								<div className="pull-right">
									<OverlayTrigger placement="top" overlay={
										<Tooltip id="tooltip-randomize">Randomize</Tooltip>
									}>
										<Button bsStyle="default" disabled={this.state.loading} onClick={this.poll}><i className={classNames({"fa fa-refresh": true, "fa-spin": this.state.loading})}></i></Button>
									</OverlayTrigger>
								</div>
							</h1>

							<br />
							<div className={classNames({"mikuia-loading": this.state.loading})}>
								<For each="channel" of={this.state.channels}>
									<Card key={channel.username}>
										<CardBlock flexBasis={300}>
											<CardBlockUser username={channel.username} link={"/levels/" + channel.username} postfix=" Levels" />
										</CardBlock>

										<CardBlock flexBasis={125} alignRight title="Unique Viewers" value={channel.users.toString()} />
										<CardBlock flexBasis={125} alignRight title="Your Rank" value="-" />
										<CardBlock flexBasis={125} alignRight title="Your Level" value="-" />
										<CardBlock flexBasis={125} alignRight title="Progress" value="-" />

									</Card>
								</For>
							</div>
							<If condition={this.state.channels.length == 0}>
								<span className="text-muted"><i className="fa fa-spinner fa-spin"></i> Loading...</span>
							</If>
						</Col>
					</Row>
				</Grid>
			</div>
		)
	}

})

export default Levels