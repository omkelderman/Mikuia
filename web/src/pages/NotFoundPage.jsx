import React from 'react'
import {LinkContainer} from 'react-router-bootstrap'
import {Button, Col, Row} from 'react-bootstrap'

import ErrorPage from '../components/community/ErrorPage'

var NotFoundPage = React.createClass({

	componentDidMount: function() {
		var self = this
		this.props.resetHeaderOptions(function() {
			self.props.setHeaderOption('extended', true)
			self.props.setHeaderOption('error', true)
		})
	},

	componentWillUnmount: function() {
		this.props.resetHeaderOptions()
	},

	render: function() {
		return (
			<div>
				<ErrorPage>
					<h3>Route not found.</h3>
					<br />
					<p>
						I'm not sure what you're looking for, but it doesn't exist.
						<br />
						Seriously, don't do that again.
					</p>
				</ErrorPage>
			</div>
		)
	},

})

export default NotFoundPage