import React from 'react'

import {Col, Grid, Row} from 'react-bootstrap'
import {translate} from 'react-i18next'

var Guide = React.createClass({
	render: function() {
		const {t} = this.props
		return (
			<div>
				<Grid>
					<Row>
						<Col md={12} mdPush={8}>
							<h1>:(</h1>
						</Col>
					</Row>
				</Grid>
			</div>
		)
	}

})

export default translate('guide', {wait: true})(Guide)