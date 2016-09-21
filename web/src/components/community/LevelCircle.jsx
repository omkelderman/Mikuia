import classNames from 'classnames'
import React from 'react'

import Tools from '../../tools'

var LevelCircle = React.createClass({
	brightColors: [
		'#b3ee00',
		'#00ffff'
	],

	colorThresholds: [
		[10, '#d2d500'],
		[20, '#b3ee00'],
		[30, '#ff9600'],
		[40, '#ff0000'],
		[50, '#00ffff'],
		[60, '#009fff'],
		[70, '#7a62d3'],
		[80, '#fc00ff'],
		[90, '#7700a9'],
		[100, '#00a938']
	],

	determineBackgroundColor: function(level) {
		if(level < 100) {
			return 'transparent'
		} else {
			return this.determineColor(level)
		}

	},

	determineColor: function(level) {
		var color = '#777'

		for(var i in this.colorThresholds) {
			if((level % 100) >= this.colorThresholds[i][0]) {
				color = this.colorThresholds[i][1]
			}
		}

		return color
	},

	determineTextColor: function(level) {
		if(level < 100) {
			return 'black'
		} else {
			if(this.brightColors.indexOf(this.determineColor(level)) > -1) {
				return 'black'
			} else {
				return 'white'
			}
		}

	},

	render: function() {
		return (
			<span>
				<span style={{fontWeight: 300}}>
					<span className={classNames({
						"mikuia-level mikuia-mini-level": true,
						"mikuia-animation-pulse": Tools.getLevel(this.props.experience) > 199
					})} style={{
						backgroundColor: this.determineBackgroundColor(Tools.getLevel(this.props.experience)),
						borderColor: this.determineColor(Tools.getLevel(this.props.experience)),
						color: this.determineTextColor(Tools.getLevel(this.props.experience))
					}}>
						<span className="mikuia-mini-level-text">{Tools.getLevel(this.props.experience)}</span>
					</span>
				</span>
			</span>
		)
	}
})

export default LevelCircle