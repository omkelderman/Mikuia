import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'

import {Link} from 'react-router'
import {Button, Col, Grid, Media, Row} from 'react-bootstrap'
import {LinkContainer} from 'react-router-bootstrap'

var CardBlockUser = React.createClass({

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
			<div className="mikuia-card-user">
				<LinkContainer to={(this.props.link ? this.props.link : '/user/' + this.props.username)}>
					<div className="mikuia-card-user-avatar">
						<img src={this.state.user.logo} width="32" height="32" />
					</div>
				</LinkContainer>
				<LinkContainer to={(this.props.link ? this.props.link : '/user/' + this.props.username)}>
					<div className="mikuia-card-user-name">
						<h4><a>{this.state.user.displayName}{this.props.postfix}</a></h4>
					</div>
				</LinkContainer>
			</div>
		)
	}

})

export default CardBlockUser