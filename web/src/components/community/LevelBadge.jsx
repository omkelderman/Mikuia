import React from 'react'
import $ from 'jquery'

import {LinkContainer} from 'react-router-bootstrap'
import {OverlayTrigger, Tooltip} from 'react-bootstrap'

import LevelCircle from './LevelCircle'

var LevelBadge = React.createClass({

	componentDidMount: function() {
		this.poll()
	},

	getInitialState: function() {
		return {
			error: false,
			user: {
				displayName: this.props.username,
				logo: ''
			}
		}
	},

	poll: function() {
		var self = this
		$.get('/api/user/' + this.props.username).success(function(data) {
			self.setState({
				user: data.user
			})
		}).fail(function() {
			self.setState({
				error: true,
				user: {}
			})
		})
	},

	render: function() {
		return (
			<div className="mikuia-level-badge">
				<LinkContainer to={'/user/' + this.props.username}>
					<a>
						<OverlayTrigger placement="top" overlay={
							<Tooltip>{this.state.user.displayName}</Tooltip>
						}>
							<img className="mikuia-level-badge-image" src={this.state.user.logo} width="50" height="50" />
						</OverlayTrigger>
					</a>
				</LinkContainer>
				
				<div className="mikuia-level-badge-level">
					<Choose>
						<When condition={this.props.to}>
							<LinkContainer to={this.props.to}>
								<a>
									<LevelCircle experience={this.props.experience} />
								</a>
							</LinkContainer>
						</When>
						<Otherwise>
							<LevelCircle experience={this.props.experience} />
						</Otherwise>
					</Choose>
				</div>
			</div>
		)
	}
})

export default LevelBadge