import React from 'react'
import {Col, Grid, Row} from 'react-bootstrap'
import {translate} from 'react-i18next'

import StreamGrid from '../components/community/StreamGrid'

var Streams = React.createClass({

	componentDidMount: function() {
		this.props.setHeaderOption('title', ['Channels'])
	},

	render: function() {
		const {t} = this.props
		return (
			<div>
				<Grid>
					<Row>
						<Col md={12}>
							<h1 className="mikuia-page-header-text">{t('streams:title')}</h1>
						</Col>
					</Row>
					<Row>
						<StreamGrid source="/api/streams" />
					</Row>
				</Grid>
			</div>
		)
	}

})

export default translate('streams', {wait: true})(Streams)