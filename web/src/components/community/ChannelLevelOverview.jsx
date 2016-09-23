import React from 'react'
import $ from 'jquery'
import {translate} from 'react-i18next'

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
		const {t} = this.props
		var self = this
		return (
			<div>
				<If condition={!this.state.loading && this.state.total > 0}>
					<LinkContainer to={'/levels/' + this.props.username}>
						<span>
							<i className="fa fa-user"></i>&nbsp; 
							<a>
								{Tools.commas(this.state.total)} {t('user:profile.uniqueViewers', {count: this.state.total})}
							</a>
						</span>
					</LinkContainer>

					<br />

					<div className="mikuia-level-badge-container">
						{this.state.users.map(function(user, i) {
							if(i < 6) {
								return <LevelBadge key={user.username} username={user.username} experience={user.experience}  to={'/levels/' + self.props.username} />
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

export default translate('user', {wait: true})(ChannelLevelOverview)