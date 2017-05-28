import classNames from 'classnames'
import React from 'react'
import {translate, Interpolate} from 'react-i18next'

import {Col, Grid, Nav, Navbar, NavItem, Row} from 'react-bootstrap'
import {LinkContainer} from 'react-router-bootstrap'

var Footer = React.createClass({
	render: function() {
		const {t} = this.props
		return (
			<div className="mikuia-footer" id="footer">
				<Grid>
					<Col md={3}>
						<small className="text-muted">
							<Interpolate i18nKey='footer:author' author={<a href="http://twitch.tv/lauriys">lauriys</a>} />
						</small>
					</Col>
					<Col md={3}></Col>
					<Col md={3}></Col>
					<Col md={3}>
						<small className="text-muted pull-right">
							<Interpolate i18nKey='footer:art' author={<a href="http://howlingneko.deviantart.com">HowlingNeko</a>} />
						</small>
					</Col>
				</Grid>
			</div>
		)
	}
})

export default translate('footer', {wait: true})(Footer)