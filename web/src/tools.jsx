var Tools = {
	commas: function(number) {
		var parts = parseFloat(number).toString().split('.')
		parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',')
		return parts.join('.')
	},

	getExperience: function(level) {
		if(level > 0) {
			return (((level * 20) * level * 0.8) + level * 100) - 16
		} else {
			return 0
		}
	},

	getLevel: function(experience) {
		var level = 0
		while(experience >= this.getExperience(level)) {
			level++
		}

		return level - 1
	},

	getLevelProgress: function(experience) {
		var level = this.getLevel(experience)
		var currentExp = experience - this.getExperience(level)
		var nextLevelExp = this.getExperience(level + 1) - this.getExperience(level)

		return Math.floor((currentExp / nextLevelExp) * 100)
	}

}

export default Tools