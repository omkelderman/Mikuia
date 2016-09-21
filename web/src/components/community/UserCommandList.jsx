import React from 'react'
import $ from 'jquery'

import {LinkContainer} from 'react-router-bootstrap'

import UserCommand from './UserCommand'

var UserCommandList = React.createClass({

	componentDidMount: function() {
		this.poll()
	},

	getInitialState: function() {
		return {
			error: false,
			loading: true,
			commands: []
		}
	},

	poll: function() {
		var self = this
		$.get('/api/user/' + this.props.username + '/commands').success(function(data) {
			self.setState({
				commands: data.commands,
				loading: false
			})
		}).fail(function() {
			self.setState({
				error: true,
				loading: false,
				commands: []
			})
		})
	},

	render: function() {
		return (
			<div>
				<If condition={!this.state.loading}>
					<For each="command" of={this.state.commands}>
						<UserCommand data={command} />
					</For>
				</If>
				<If condition={this.state.loading}>
					<i className="fa fa-spinner fa-spin text-muted" /> Loading commands...
				</If>
			</div>
		)
	}

})

export default UserCommandList