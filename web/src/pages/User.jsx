import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'

import {AutoAffix} from 'react-overlays'
import {Col, Grid, Row, Tab, Tabs} from 'react-bootstrap'
import {LinkContainer} from 'react-router-bootstrap'

import ChannelLevelOverview from '../components/community/ChannelLevelOverview'
import ErrorPage from '../components/community/ErrorPage'
import LevelCircle from '../components/community/LevelCircle'
import UserCommandList from '../components/community/UserCommandList'
import UserLevelOverview from '../components/community/UserLevelOverview'

var User = React.createClass({

	changeTab: function(tab) {
		this.setState({
			activeTab: tab
		})
	},

	componentDidMount: function() {
		var self = this
		this.props.resetHeaderOptions(function() {
			self.props.setHeaderOption('extended', true)
			self.props.setHeaderOption('splash', false)
		})

		this.poll()
	},

	componentWillUnmount: function() {
		this.props.resetHeaderOptions()
	},

	getInitialState: function() {
		return {
			activeTab: 'commands',
			affixed: false,
			error: false,
			user: {
				bio: null,
				displayName: this.props.params.username,
				experience: 0,
				level: '-',
				logo: ''
			}
		}
	},

	onAffix: function() {
		this.setState({
			affixed: true
		})
	},

	onAffixTop: function() {
		this.setState({
			affixed: false
		})
	},

	poll: function() {
		var self = this
		$.get('/api/user/' + this.props.params.username).success(function(data) {
			self.setState({
				user: data.user
			})
			self.props.setHeaderOption('background', data.user.profileBanner)
		}).fail(function() {
			self.props.setHeaderOption('error', true)
			self.setState({
				error: true,
				user: {}
			})
		})
	},

	render: function() {
		return (
			<div>
				<Choose>
					<When condition={!this.state.error}>
						<div className="mikuia-page-padding-extended">
							<div className="mikuia-profile-nav-container">
								<AutoAffix viewportOffsetTop={0} container={this} affixClassName="affixed" onAffix={this.onAffix} onAffixTop={this.onAffixTop}>
									<div className="mikuia-profile-nav">
										<Grid>
											<Row>
												<Col md={12}>
													<If condition={this.state.affixed}>
														<ul className="mikuia-profile-nav-card">
															<li>
																<img src={this.state.user.logo} width="38" height="38" /><span>{this.state.user.displayName}</span>
															</li>
														</ul>
													</If>
													<ul className="mikuia-profile-nav-tabs">
														<li className={classNames({"active": this.state.activeTab == "activity", "disabled": true})}><i className="fa fa-th-list"></i>&nbsp; Activity</li>
														<li onClick={() => this.changeTab("commands")} className={classNames({"active": this.state.activeTab == "commands"})}><i className="fa fa-wrench"></i>&nbsp; Commands</li>
														<li className={classNames({"active": this.state.activeTab == "statistics", "disabled": true})}><i className="fa fa-bar-chart"></i>&nbsp; Statistics</li>
													</ul>
												</Col>
											</Row>
										</Grid>
									</div>
								</AutoAffix>
							</div>
							<Grid className="mikuia-profile-content">
								<Row>
									<Col md={3}>
										<div className="mikuia-profile-sidebar">
											<img className="mikuia-profile-avatar" src={this.state.user.logo} width="220" height="220" />
											<h2>{this.state.user.displayName}</h2>

											Level <LevelCircle experience={this.state.user.experience} />
											<br />
											<br />
											<If condition={this.state.user.bio && this.state.user.bio != 'null' && this.state.user.bio != 'undefined'}>
												<i className="text-muted">
													{this.state.user.bio}
												</i>
												<br />
												<br />
											</If>

											<UserLevelOverview username={this.props.params.username} />
											<ChannelLevelOverview username={this.props.params.username} />

										</div>
									</Col>
									<Col md={6}>
										<Choose>
											<When condition={this.state.activeTab == 'activity'}>
												<h4>they streamed something</h4>
												<br />
												<h4>they achieved something</h4>
												<br />
												<h4>they did something</h4>
												<br />
												<h4>you get the point</h4>
												<br />
												lorem ipsum
											</When>
											<When condition={this.state.activeTab == 'commands'}>
												<UserCommandList username={this.props.params.username} />
											</When>
											<When condition={this.state.activeTab == 'statistics'}>
												<h3>stats here</h3>
											</When>
										</Choose>
									</Col>
									<Col md={3}>
										<a href={"http://twitch.tv/" + this.props.params.username} target="_blank"><i className="fa fa-twitch"></i> Twitch</a>
									</Col>
								</Row>
							</Grid>
						</div>
					</When>
					<Otherwise>
						<ErrorPage>
							<h3>That user does not exist.</h3>
							<br />
							<p>
								I don't know what happened to them.
								<br />
								Maybe they never existed in the first place?
								<br />
								Sorry for not being able to help you.
							</p>
						</ErrorPage>

					</Otherwise>
				</Choose>
			</div>
		)
	}

})

export default User