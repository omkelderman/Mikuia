import React from 'react'

module.exports = {

	Authenticated: React.createClass({
		contextTypes: {
			auth: React.PropTypes.bool,
			user: React.PropTypes.object
		},

		render: function() {
			return (
				<div>
					<If condition={this.context.auth}>
						{this.props.children}
					</If>
				</div>
			)
		}
	}),

	NotAuthenticated: React.createClass({
		contextTypes: {
			auth: React.PropTypes.bool,
			user: React.PropTypes.object
		},

		render: function() {
			return (
				<div>
					<If condition={!this.context.auth}>
						{this.props.children}
					</If>
				</div>
			)
		}
	})

}