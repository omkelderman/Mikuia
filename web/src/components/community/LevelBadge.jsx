import React from 'react'
import $ from 'jquery'

import {LinkContainer} from 'react-router-bootstrap'

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
				<img className="mikuia-level-badge-image" src={this.state.user.logo} width="50" height="50" />
				<div className="mikuia-level-badge-level">
					<LevelCircle experience={this.props.experience} />
				</div>
			</div>
		)
	}
})

export default LevelBadge