import classNames from 'classnames'
import React from 'react'

import {Col, Grid, Nav, Navbar, NavItem, Row} from 'react-bootstrap'
import {LinkContainer} from 'react-router-bootstrap'

import {Authenticated, NotAuthenticated} from '../Auth'

var Header = React.createClass({
	contextTypes: {
		auth: React.PropTypes.bool,
		user: React.PropTypes.object
	},

	render: function() {
		return (
			<span id="header">
				<Choose>
					<When condition={this.props.options.extended && this.props.options.background && !this.props.options.error}>
						<div className="mikuia-navbar-background" style={{background: 'linear-gradient(rgba(0, 0, 0, 0.7), rgba(0, 0, 0, 0.7)), url(\'' + this.props.options.background + '\')'}} />
					</When>
					<When condition={this.props.options.extended && !this.props.options.background && !this.props.options.error}>
						<div className="mikuia-navbar-background" style={{backgroundColor: this.props.options.color}} />
					</When>
					<When condition={this.props.options.error}>
						<div className="mikuia-navbar-background" style={{backgroundColor: '#000000', height: '100%'}} />
					</When>
				</Choose>
				<Navbar bsClass="mikuia" className={classNames({'mikuia-navbar': true, 'mikuia-navbar-extended': this.props.options.extended, 'mikuia-navbar-splash': this.props.options.splash})}>
					<div className="mikuia-navbar-content">
						<LinkContainer to="/home">
							<a>
								<img className="mikuia-navbar-icon" src="/img/icon.png" width="50" height="50" />
							</a>
						</LinkContainer>

						<div className="mikuia-navbar-lines-left">
							<div className="mikuia-navbar-links">
								<LinkContainer to="/home">
									<a>Home</a>
								</LinkContainer>
								<LinkContainer to="/streams">
									<a>Streams</a>
								</LinkContainer>
								<LinkContainer to="/levels">
									<a>Levels</a>
								</LinkContainer>
								<LinkContainer to="#">
									<a>Guides</a>
								</LinkContainer>
								<LinkContainer to="/supporter">
									<a>Supporter</a>
								</LinkContainer>
								<LinkContainer to="/leagues">
									<a>Leagues</a>
								</LinkContainer>
								<a href="https://p.datadoghq.com/sb/AF-ona-ccd2288b29">Status</a>
							</div>

							<div className="mikuia-navbar-title">
								<span>
									<span>Mikuia.tv</span>
								</span>
							</div>
						</div>

						<div className="mikuia-navbar-lines-right">

							<Authenticated>
								<div className="mikuia-navbar-links">
									<LinkContainer to={"/user/" + this.context.user.username}>
										<a>Profile</a>
									</LinkContainer>
									<LinkContainer to="/settings">
										<a>Settings</a>
									</LinkContainer>
									<a href="/dashboard">Dashboard</a>
									<a href="/logout">Logout</a>
								</div>
								<div className="mikuia-navbar-title">
									<span>
										<LinkContainer to={"/user/" + this.context.user.username}>
											<a>{this.context.user.displayName}</a>
										</LinkContainer>
									</span>
								</div>
							</Authenticated>
							
							<NotAuthenticated>
								<div className="mikuia-navbar-links mikuia-navbar-login-link">
									<a href="/auth/twitch"><i className="fa fa-twitch" /> Login with Twitch</a>
								</div>
							</NotAuthenticated>

						</div>

						<Authenticated>
							<LinkContainer to={"/user/" + this.context.user.username}>
								<a>
									<img className="mikuia-navbar-avatar" src={this.context.user.logo} width="80" height="80" />
								</a>
							</LinkContainer>
						</Authenticated>
						
					</div>
				</Navbar>
				<br />
			</span>
		)
	}
})

export default Header