import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'

import {Link} from 'react-router'
import {Button, Col, Grid, Media, Row} from 'react-bootstrap'
import {LinkContainer} from 'react-router-bootstrap'

var CardBlockSource = React.createClass({

	componentDidMount: function() {
		this.poll()
	},

	getInitialState: function() {
		return {
			error: false,
			loading: true,
			data: null
		}
	},

	poll: function() {
		var self = this
		$.get(this.props.url).success(function(data) {
			self.setState({
				data: data,
				loading: false
			})
		}).fail(function() {
			self.setState({
				error: true,
				loading: false,
				data: null
			})
		})
	},

	render: function() {

		var innerText = (
			<h3>
				<If condition={!this.state.loading}>
					<Choose>
						<When condition={this.props.value}>
							{this.props.prefix}{this.state.data[this.props.value]}{this.props.postfix}
						</When>
						<Otherwise>
							{this.props.prefix}{this.state.data}{this.props.postfix}
						</Otherwise>
					</Choose>
				</If>
				<If condition={this.state.loading}>
					<i className="fa fa-spinner fa-spin text-muted" />
				</If>
			</h3>
		)

		return (
			<div className={classNames({"mikuia-card-block": true, "align-right": this.props.alignRight, "mikuia-card-ranking-block": this.props.ranking})} style={{flexBasis: this.props.flexBasis + 'px'}}>
				<If condition={this.props.title}>
					<h6 className="text-muted">{this.props.title}</h6>
				</If>
				<Choose>
					<When condition={this.props.link && !this.state.loading}>
						<LinkContainer to={this.props.link}>
							<a>{innerText}</a>
						</LinkContainer>
					</When>
					<Otherwise>
						{innerText}
					</Otherwise>
				</Choose>
			</div>
		)
	}

})

export default CardBlockSource