import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'
import {Col, Grid, Row} from 'react-bootstrap'

import Card from '../components/community/Card'
import CardBlock from '../components/community/CardBlock'
import CardBlockSource from '../components/community/CardBlockSource'
import CardBlockUser from '../components/community/CardBlockUser'
import LevelCircle from '../components/community/LevelCircle'
import ErrorPage from '../components/community/ErrorPage'

import Tools from '../tools'

var UserLevels = React.createClass({

	addLevels: function(offset) {
		var shownLevels = this.state.shownLevels.slice(0)
		var endOffset = Math.min(offset + 30, this.state.levels.length)
		for(var i = offset; i < endOffset; i++) {
			shownLevels.push(this.state.levels[i])
		}
		this.setState({
			loading: false,
			shownLevels: shownLevels,
			offset: endOffset
		})
	},

	componentDidMount: function() {
		var self = this
		this.props.resetHeaderOptions(function() {
			self.props.setHeaderOption('extended', true)
			self.props.setHeaderOption('splash', false)
		})

		this.poll()

		$(window).scroll(function() {
			if($('body').height() <= ($(window).height() + $(window).scrollTop())) {
				if(!self.state.loading) {
					self.setState({
						loading: true
					})
					self.loadLevels(self.state.offset)
				}
			}
		})

	},

	componentWillUnmount: function() {
		$(window).unbind('scroll')

		this.props.resetHeaderOptions()
	},

	getInitialState: function() {
		return {
			levels: [],
			shownLevels: [],
			user: {
				displayName: this.props.params.username,
				logo: ''
			},
			offset: 0,
			error: false,
			loading: true
		}
	},

	loadLevels: function(offset) {
		var self = this
		var levels = self.state.levels
		if(levels.length == 0) {
			$.get('/api/user/' + this.props.params.username + '/levels').success(function(data) {
				for(var userId in data.levels) {
					levels.push(data.levels[userId])
				}

				self.setState({
					levels: levels,
					offset: 0,
					loading: false
				}, function() {
					self.addLevels(0)
				})

			}).fail(function() {
				self.setState({
					error: true,
					loading: false,
					levels: levels
				})
			})
		} else {
			self.addLevels(this.state.offset)
		}
	},

	poll: function() {
		var self = this
		self.setState({
			loading: true
		})

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

		this.loadLevels(0)
	},

	render: function() {
		return (
			<Grid>
				<Choose>
					<When condition={!this.state.error}>
						<div className="mikuia-page-padding">
							<Row>
								<Col md={8}>
									<h1 className="mikuia-page-header-text text-white">{this.state.user.displayName}'s Levels</h1>
								</Col>
							</Row>

							<Row>
								<Col md={8} className="mikuia-page-card">
									<For each="user" index="i" of={this.state.shownLevels}>
										<Card ranking key={user.username}>
											<CardBlock flexBasis={250}>
												<CardBlockUser username={user.username} link={"/levels/" + user.username} postfix=" Level" />
											</CardBlock>

											<CardBlock flexBasis={150} alignRight title="Experience" value={Tools.commas(user.experience)} />
											<CardBlockSource flexBasis={150} alignRight title="Rank" url={"/api/user/" + this.props.params.username + "/levels/" + user.username} value="rank" prefix="#" link={"/levels/" + user.username}/>
											<CardBlock flexBasis={70} alignRight title="Level">
												<LevelCircle experience={user.experience} />
											</CardBlock>
											<CardBlock flexBasis={100} alignRight title="Progress" value={Tools.getLevelProgress(user.experience) + "%"} />
										</Card>
									</For>
									<If condition={this.state.loading}>
										<Card>
											<CardBlock flexBasis={20}>
												<i className="fa fa-spinner fa-spin" />
											</CardBlock>
										</Card>
									</If>
								</Col>
							</Row>
						</div>
					</When>
					<Otherwise>
						<ErrorPage>
							<h3>That user does not exist.</h3>
							<br />
							<p>
								Can't check the levels of a person that does not exist!
								<br />
								You can try creating a person and then try again.
								<br />
								Please be careful.
							</p>
						</ErrorPage>
					</Otherwise>
				</Choose>
			</Grid>
		)
	}

})

export default UserLevels