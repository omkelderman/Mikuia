import React from 'react'
import $ from 'jquery'

import {LinkContainer} from 'react-router-bootstrap'

import LevelBadge from './LevelBadge'

import Tools from '../../tools'

var ChannelLevelOverview = React.createClass({

	componentDidMount: function() {
		this.poll()
	},

	getInitialState: function() {
		return {
			error: false,
			loading: true,
			users: [],
			total: '-'
		}
	},

	poll: function() {
		var self = this
		$.get('/api/levels/' + this.props.username).success(function(data) {
			self.setState({
				users: data.users,
				loading: false,
				total: data.total
			})
		}).fail(function() {
			self.setState({
				error: true,
				loading: false,
				users: []
			})
		})
	},

	render: function() {
		return (
			<div>
				<If condition={!this.state.loading && this.state.total > 0}>
					<LinkContainer to={"/levels/" + this.props.username}>
						<span>
							<i className="fa fa-user"></i>&nbsp; 
							<a>
								{Tools.commas(this.state.total)} unique viewers
							</a>
						</span>
					</LinkContainer>

					<br />

					<div className="mikuia-level-badge-container">
						{this.state.users.map(function(user, i) {
							if(i < 6) {
								return <LevelBadge username={user.username} experience={user.experience} />
							}
						})}
					</div>
				</If>
				<If condition={this.state.loading}>
					<i className="fa fa-spinner fa-spin text-muted" />
				</If>
			</div>
		)
	}

})

export default ChannelLevelOverview