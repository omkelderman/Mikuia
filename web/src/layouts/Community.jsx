import classNames from 'classnames'
import React from 'react'
import $ from 'jquery'

import {Col, Grid, Nav, Navbar, NavItem, Row} from 'react-bootstrap'
import {LinkContainer} from 'react-router-bootstrap'

import Header from '../components/community/Header'

var Community = React.createClass({
	childContextTypes: {
		auth: React.PropTypes.bool,
		user: React.PropTypes.object
	},

	componentDidMount: function() {
		var self = this
		$.get('/api/user').success(function(data) {
			self.setState({
				auth: data.auth,
				user: {
					username: data.username,
					displayName: data.displayName,
					logo: data.logo
				}
			})
		})
	},

	getChildContext: function() {
		return {
			auth: this.state.auth,
			user: this.state.user
		}
	},

	getInitialState: function() {
		return {
			auth: false,
			header: {
				background: null,
				color: '#7a62d3',
				error: false,
				extended: false,
				splash: false
			},
			user: {}
		}
	},

	render: function() {
		return (
			<div>
				<If condition={this.props.location.pathname == '/home'}>
					<div className="mikuia-navbar-background" style={{backgroundColor: '#111', height: '600px'}}>

					</div>
				</If>

				<Header options={this.state.header} pathName={this.props.location.pathname} />
				
				{React.cloneElement(this.props.children, {
					key: this.props.location.pathname,
					resetHeaderOptions: this.resetHeaderOptions,
					setHeaderOption: this.setHeaderOption
				})}
			</div>
		)
	},

	resetHeaderOptions: function(callback) {
		this.setState({header: this.getInitialState().header}, function() {
			if(callback) {
				callback()
			}
		})
	},

	setHeaderOption: function(option, value) {
		var newState = {
			header: this.state.header
		}

		newState.header[option] = value

		this.setState(newState)
	}

})

export default Community