var Mikuia = {
	usernameCompletion: function(element, openAfterSelect) {
		options = {
			delay: 250,
			items: 5,
			minLength: 1,
			source: function(query, process) {
				$.post('/search', {
					type: 'username-completion',
					query: query
				}).success(function(result) {
					process(JSON.parse(result))
				})
			}
		}
		if(openAfterSelect) {
			options.afterSelect = function(item) {
				window.location = '/user/' + item.toLowerCase()
			}
		}
		element.typeahead(options)
	}
}