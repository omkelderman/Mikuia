import React from 'react'

import {browserHistory} from 'react-router'
import {Button, Col, Grid, Row} from 'react-bootstrap'
import {translate} from 'react-i18next'

var Card = React.createClass({

	render: function() {
		const {t} = this.props
		return (
			<div className="mikuia-error">
				<Grid>
					<Row>
						<Col md={12}>
							<h1>{t('common:error.title')}</h1>

							{this.props.children}
							<br />
							<a onClick={browserHistory.goBack}>{t('common:error.back')}</a>
						</Col>
					</Row>
				</Grid>
			</div>
		)
	}

})

export default translate('common', {wait: true})(Card)