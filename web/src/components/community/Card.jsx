import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'

import {Link} from 'react-router'
import {Button, Col, Grid, Media, Row} from 'react-bootstrap'

var Card = React.createClass({

	render: function() {
		return (
			<div className={classNames({"mikuia-card": true, "mikuia-card-ranking": this.props.ranking})}>
				{this.props.children}
			</div>
		)
	}

})

export default Card