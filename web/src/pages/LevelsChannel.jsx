import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'
import {Col, Grid, Row} from 'react-bootstrap'

import Card from '../components/community/Card'
import CardBlock from '../components/community/CardBlock'
import CardBlockUser from '../components/community/CardBlockUser'
import LevelCircle from '../components/community/LevelCircle'

import Tools from '../tools'

var LevelsChannel = React.createClass({

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
			users: [],
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
		var users = self.state.users
		$.get('/api/levels/' + this.props.params.username + '?limit=50&offset=' + offset).success(function(data) {
			for(var userId in data.users) {
				users.push(data.users[userId])
			}

			self.setState({
				users: users,
				offset: self.state.offset + 50,
				loading: false
			})

		}).fail(function() {
			self.setState({
				error: true,
				loading: false,
				users: users
			})
		})
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
				<div className="mikuia-page-padding">
					<Row>
						<Col md={8}>
							<h1 className="mikuia-page-header-text text-white">{this.state.user.displayName} Levels</h1>
						</Col>
					</Row>

					<Row>
						<Col md={8} className="mikuia-page-card">
							<For each="user" index="i" of={this.state.users}>
								<Card ranking key={user.username}>
									<CardBlock ranking flexBasis={80} title="Rank" value={"#" + (i + 1)} />

									<CardBlock flexBasis={300}>
										<CardBlockUser username={user.username} />
									</CardBlock>

									<CardBlock flexBasis={150} alignRight title="Experience" value={Tools.commas(user.experience)} />
									<CardBlock flexBasis={50} alignRight title="Level">
										<LevelCircle experience={user.experience} />
									</CardBlock>
									<CardBlock flexBasis={70} alignRight title="Progress" value={Tools.getLevelProgress(user.experience) + "%"} />
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
			</Grid>
		)
	}

})

export default LevelsChannel