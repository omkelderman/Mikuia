import classNames from 'classnames'
import React from 'react'
import { translate } from 'react-i18next'

import {Col, Dropdown, Grid, MenuItem, Nav, Navbar, NavItem, Row} from 'react-bootstrap'
import {LinkContainer} from 'react-router-bootstrap'

import {Authenticated, NotAuthenticated} from '../Auth'
import LinkDropdownToggle from './LinkDropdownToggle'

var Header = React.createClass({
	contextTypes: {
		auth: React.PropTypes.bool,
		user: React.PropTypes.object
	},

	getBasePath: function() {
		return this.props.pathName.split('/')[1]
	},

	getLanguageFlagPath: function() {
		var lng = localStorage.getItem('lang').split('-')[0] || 'en'

		return '/img/flags/' + lng + '.png'
	},

	render: function() {
		const {t} = this.props
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
									<a className={classNames({active: this.getBasePath() == 'home'})}>{t('header:link.home')}</a>
								</LinkContainer>
								<LinkContainer to="/streams">
									<a className={classNames({active: this.getBasePath() == 'streams'})}>{t('header:link.channels')}</a>
								</LinkContainer>
								<LinkContainer to="/levels">
									<a className={classNames({active: this.getBasePath() == 'levels'})}>{t('header:link.levels')}</a>
								</LinkContainer>
								<LinkContainer to="/guides">
									<a className={classNames({active: this.getBasePath() == 'guides'})}>{t('header:link.guides')}</a>
								</LinkContainer>
								<LinkContainer to="/leagues">
									<a className={classNames({active: this.getBasePath() == 'leagues'})}>{t('header:link.leagues')}</a>
								</LinkContainer>
								<a href="https://p.datadoghq.com/sb/AF-ona-ccd2288b29">{t('header:link.status')}</a>
								<Dropdown className="mikuia-navbar-dropdown" id="dropdown-language">
									<LinkDropdownToggle bsRole="toggle">
										<img src={this.getLanguageFlagPath()} />  <span className="caret"></span>
									</LinkDropdownToggle>
									<Dropdown.Menu>
										<MenuItem onClick={() => {localStorage.setItem('lang', 'de-DE'); window.location.reload()}}><img src="/img/flags/de.png" /> Deutsch</MenuItem>
										<MenuItem onClick={() => {localStorage.setItem('lang', 'en'); window.location.reload()}}><img src="/img/flags/en.png" /> English</MenuItem>
										<MenuItem onClick={() => {localStorage.setItem('lang', 'fr-FR'); window.location.reload()}}><img src="/img/flags/fr.png" /> Français</MenuItem>
									</Dropdown.Menu>
								</Dropdown>
								
							</div>
							<div className="mikuia-navbar-title">
								<span>
									<span>{this.props.options.title.map((item, i, arr) => {
										let divider = i < arr.length - 1 && <i className="fa fa-angle-right" />
										return (
											<span>
												<span key={i}>{item}</span>{divider}
											</span>
										)
									})}</span>
								</span>
							</div>
						</div>

						<div className="mikuia-navbar-lines-right">

							<Authenticated>
								<div className="mikuia-navbar-links">
									<LinkContainer to={"/user/" + this.context.user.username}>
										<a className={classNames({active: this.getBasePath() == 'user' && this.props.pathName.split('/')[2] == this.context.user.username})}>{t('header:user.profile')}</a>
									</LinkContainer>
									<LinkContainer to="/settings">
										<a className={classNames({active: this.getBasePath() == 'settings'})}>{t('header:user.settings')}</a>
									</LinkContainer>
									<a href="/dashboard">{t('header:user.dashboard')}</a>
									<a href="/logout">{t('header:user.logout')}</a>
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
									<a href="/auth/twitch"><i className="fa fa-twitch" /> {t('header:login.twitch')}</a>
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

export default translate('header', {wait: true})(Header)