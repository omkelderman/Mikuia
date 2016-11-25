import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'
import { translate, Interpolate } from 'react-i18next'

import {Link} from 'react-router'
import {Button, Col, Grid, Media, Row} from 'react-bootstrap'

var FeaturedStream = React.createClass({

	componentDidMount: function() {
		this.poll()
	},

	getInitialState: function() {
		return {
			error: null,
			stream: {
				broadcaster_language: null,
				game: '...',
				status: '...'
			}
		}
	},

	poll: function() {
		var self = this
		$.get('/api/streams/featured').success(function(data) {
			self.setState({
				error: false,
				stream: data.featured
			})
		}).fail(function() {
			self.setState({
				error: true,
				stream: {}
			})
		})
	},

	render: function() {
		const {t} = this.props
		var backgroundStyle = 'linear-gradient(rgba(0, 0, 0, 0.8), rgba(0, 0, 0, 0.8))'
		if(this.state.stream.profile_banner) {
			backgroundStyle += ', url("' + this.state.stream.profile_banner +'")'
		}

		return (
			<div>
				<If condition={this.state.error == false}>
					<div className="mikuia-index-featured" style={{background: backgroundStyle}}>
						<div className="mikuia-index-featured-background">
							<div className="container text-white">
								<Row>
									<Col xs={4}>
										<iframe src={"http://player.twitch.tv/?channel=" + this.state.stream.name} frameBorder={0} scrolling={"no"} autoPlay={false} height={225} width={369} />
									</Col>
									<Col xs={8}>
										<br />
										<h4 className="text-muted">{t('home:featured.example')}</h4>
										<h1>{this.state.stream.display_name} <small><Interpolate i18nKey='streams:stream.playing' game={"osu!"} /></small></h1>
										<p>{this.state.stream.status}</p>
										<br />
										<a href={"http://twitch.tv/" + this.state.stream.name} className="btn btn-twitch btn-xs">
											<i className="fa fa-twitch" /> {t('home:featured.watch')}
										</a>
									</Col>
								</Row>
							</div>
						</div>
					</div>
				</If>
			</div>
		)
	},

})

export default translate('home', {wait: true})(FeaturedStream)