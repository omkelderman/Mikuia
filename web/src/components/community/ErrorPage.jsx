import React from 'react'

import {browserHistory} from 'react-router'
import {Button, Col, Grid, Row} from 'react-bootstrap'

var Card = React.createClass({

	render: function() {
		return (
			<div className="mikuia-error">
				<Grid>
					<Row>
						<Col md={12}>
							<h1>Damn it.</h1>

							{this.props.children}
							<br />
							<a onClick={browserHistory.goBack}>You can try going back...</a>
						</Col>
					</Row>
				</Grid>
			</div>
		)
	}

})

export default Card