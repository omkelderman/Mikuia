import React from 'react'

var LinkDropdownToggle = React.createClass({
	handleClick: function(e) {
		e.preventDefault()
		this.props.onClick(e)
	},

	render: function() {
		return (
			<a href="#" onClick={this.handleClick}>
				{this.props.children}
			</a>
		)
	}
})

export default LinkDropdownToggle