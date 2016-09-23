import React from 'react'
import $ from 'jquery'
import {translate} from 'react-i18next'

import {LinkContainer} from 'react-router-bootstrap'

import LevelBadge from './LevelBadge'

import Tools from '../../tools'

var UserLevelOverview = React.createClass({

	componentDidMount: function() {
		this.poll()
	},

	getInitialState: function() {
		return {
			error: false,
			loading: true,
			levels: []
		}
	},

	poll: function() {
		var self = this
		$.get('/api/user/' + this.props.username + '/levels').success(function(data) {
			self.setState({
				levels: data.levels,
				loading: false
			})
		}).fail(function() {
			self.setState({
				error: true,
				loading: false,
				levels: []
			})
		})
	},

	render: function() {
		const {t} = this.props
		var self = this
		return (
			<div>
				<If condition={!this.state.loading && this.state.levels.length > 0}>
					<LinkContainer to={"/user/" + this.props.username + "/levels"}>
						<span>
							<i className="fa fa-star"></i>&nbsp; 
							<a>
								{Tools.commas(this.state.levels.length)} {t('user:profile.channelsWatched', {count: this.state.levels.length})}
							</a>
						</span>
					</LinkContainer>

					<br />

					<div className="mikuia-level-badge-container">
						{this.state.levels.map(function(level, i) {
							if(i < 6) {
								return <LevelBadge key={level.username} username={level.username} experience={level.experience} to={'/user/' + self.props.username + '/levels'} />
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

export default translate('user', {wait: true})(UserLevelOverview)