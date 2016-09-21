import React from 'react'
import {Col, Grid, Row} from 'react-bootstrap'

import StreamGrid from '../components/community/StreamGrid'

var Streams = React.createClass({

	render: function() {
		return (
			<div>
				<Grid>
					<Row>
						<Col md={12}>
							<h1 className="mikuia-page-header-text">Streams</h1>
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

export default Streams