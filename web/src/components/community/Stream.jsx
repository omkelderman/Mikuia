import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'

import {Link} from 'react-router'
import {Button, Col, Grid, Media, Row} from 'react-bootstrap'

var Stream = React.createClass({

	componentDidMount: function() {
		this.poll()
	},

	getInitialState: function() {
		return {
			error: false,
			stream: {
				broadcaster_language: null,
				game: '...',
				status: '...'
			}
		}
	},

	poll: function() {
		var self = this
		$.get('/api/stream/' + this.props.username).success(function(data) {
			self.setState({
				stream: data.stream
			})
		}).fail(function() {
			self.setState({
				error: true,
				stream: {
					status: 'Error loading stream.'
				}
			})
		})
	},

	render: function() {
		return (
			<div>
				<a href={"http://twitch.tv/" + this.props.username} target="_blank">
					<Col md={3} className={classNames({"mikuia-stream": true, "mikuia-stream-error": this.state.error})} style={{backgroundImage: 'linear-gradient(to bottom, rgba(0, 0, 0, 0.1), rgba(32, 20, 73, 0.8)), url(\'' + this.state.stream.preview + '\')'}}>
						<If condition={this.state.stream.broadcaster_language != null}>
							<div className="mikuia-stream-flag">
								<img src={"/img/flags/" + this.state.stream.broadcaster_language + ".png"} />
							</div>
						</If>
						<div className="mikuia-stream-lb">
							<b>{this.state.stream.viewers}</b>
						</div>
						<div className="mikuia-stream-details">
							{this.state.stream.status}
							<div className="mikuia-stream-details-user">
								<img className="mikuia-stream-details-user-avatar" src={this.state.stream.logo} width="16" height="16" />
								<div className="mikuia-stream-details-user-name">
									<span className="text-white">{this.state.stream.display_name}</span>
									<If condition={this.state.stream.game}>
										<small> playing {this.state.stream.game}</small>
									</If>
								</div>
							</div>
						</div>
					</Col>
				</a>
			</div>
		)
	},

})

export default Stream