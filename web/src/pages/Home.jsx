import React from 'react'
import {LinkContainer} from 'react-router-bootstrap'
import {Button, Col, Row, Well} from 'react-bootstrap'

import {translate, Interpolate} from 'react-i18next'

import FeaturedStream from '../components/community/FeaturedStream'
import StreamGrid from '../components/community/StreamGrid'

var Home = React.createClass({

	componentDidMount: function() {
		var self = this
		this.props.resetHeaderOptions(function() {
			self.props.setHeaderOption('extended', false)
			self.props.setHeaderOption('splash', true)
			self.props.setHeaderOption('title', ['Mikuia.tv'])
		})
	},

	componentWillUnmount: function() {
		this.props.resetHeaderOptions()
	},

	render: function() {
		const {t} = this.props
		return (
			<div>
				<div className="container text-white">
					<br />
					<div className="mikuia-index">
						<Row>
							<Col md={5} className="align-center mikuia-index-screenshot" />
							<Col md={5} mdOffset={1}>
								<h1>Mikuia <small>{t('home:about.mikuia')}</small></h1>
								<p className="text-muted">
									<Interpolate i18nKey='home:about.description' useDangerouslySetInnerHTML={true} />
								</p>
								<br />
								<LinkContainer to="/guides/quickstart">
									<Button bsStyle="default">{t('home:about.guide')}</Button>
								</LinkContainer>
							</Col>
						</Row>
					</div>
				</div>
				<FeaturedStream />
				<Well>
					<div className="container">
						<Row>
							<Col md={12}>
								<h1>
									<LinkContainer to="/streams">
										<a>{t('home:other.title')}</a>
									</LinkContainer>
								</h1>
							</Col>
						</Row>
						<br />
						<Row>
							<StreamGrid source="/api/streams?limit=12&offset=0" pagination={false} />
						</Row>
					</div>
				</Well>
			</div>
		)
	},

})

export default translate(['home', 'streams'], {wait: true})(Home)