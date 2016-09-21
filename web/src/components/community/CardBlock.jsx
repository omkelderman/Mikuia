import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'

import {Link} from 'react-router'
import {Button, Col, Grid, Media, Row} from 'react-bootstrap'

var CardBlock = React.createClass({

	render: function() {
		return (
			<div className={classNames({"mikuia-card-block": true, "align-right": this.props.alignRight, "mikuia-card-ranking-block": this.props.ranking})} style={{flexBasis: this.props.flexBasis + 'px'}}>
				<If condition={this.props.title}>
					<h6 className="text-muted">{this.props.title}</h6>
					<h3>
						<Choose>
							<When condition={this.props.value}>
								{this.props.value}
							</When>
							<Otherwise>
								{this.props.children}
							</Otherwise>
						</Choose>
					</h3>
				</If>
				<If condition={!this.props.title}>
					{this.props.children}
				</If>
			</div>
		)
	}

})

export default CardBlock