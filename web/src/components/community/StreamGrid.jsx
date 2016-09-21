import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'

import {Link} from 'react-router'
import {Button, Col, Grid, Media, Pagination, Row} from 'react-bootstrap'

import Stream from './Stream'

var StreamGrid = React.createClass({

	componentDidMount: function() {
		this.poll()
	},

	getInitialState: function() {
		return {
			loading: true,
			limit: 16,
			offset: 0,
			streams: [],
			total: 0
		}
	},

	handleSelect: function(activePage) {
		this.setState({
			offset: activePage * 16 - 16
		}, function() {
			this.poll()
		})
	},

	poll: function() {
		var self = this
		self.setState({
			loading: true
		})
		$.get(this.props.source + '?limit=' + this.state.limit + '&offset=' + this.state.offset).success(function(data) {
			self.setState({
				loading: false,
				streams: data.streams,
				total: data.total
			})
		})
	},

	render: function() {
		return (
			<div>
				<div className={classNames({"mikuia-loading": this.state.loading})}>
					<For each="username" of={this.state.streams}>
						<Stream key={username} username={username} />
					</For>
				</div>
				<Col md={12}>
					<div className="pull-right">
						<Pagination prev next first last ellipsis boundaryLinks bsStyle="mikuia" items={Math.ceil(this.state.total / 16)} maxButtons={5} activePage={Math.floor(this.state.offset / 16) + 1} onSelect={this.handleSelect} />
					</div>
				</Col>
			</div>
		)
	},

})

export default StreamGrid