import React from 'react'
import {LinkContainer} from 'react-router-bootstrap'
import {Button, Col, Row} from 'react-bootstrap'
import {translate, Interpolate} from 'react-i18next'

import ErrorPage from '../components/community/ErrorPage'

var NotFoundPage = React.createClass({

	componentDidMount: function() {
		var self = this
		this.props.resetHeaderOptions(function() {
			self.props.setHeaderOption('extended', true)
			self.props.setHeaderOption('error', true)
			self.props.setHeaderOption('title', [self.props.t('header:details.error')])
		})
	},

	componentWillUnmount: function() {
		this.props.resetHeaderOptions()
	},

	render: function() {
		const {t} = this.props
		return (
			<div>
				<ErrorPage>
					<h3>{t('common:error.routeNotFound')}</h3>
					<br />
					<p>
						<Interpolate i18nKey='common:error.routeNotFoundDescription' useDangerouslySetInnerHTML={true} />
					</p>
				</ErrorPage>
			</div>
		)
	},

})

export default translate('common', {wait: true})(NotFoundPage)