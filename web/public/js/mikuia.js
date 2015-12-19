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

var navbarHideTimeout = null
hideNavbarLinks = function() {
	$('.mikuia-navbar-lines-left > .mikuia-navbar-links > a').removeClass('selected')
	$('.mikuia-navbar-title-links > span').hide()
	$('.mikuia-navbar-lines-left > .mikuia-navbar-title > span').show()
}

$('.mikuia-navbar-lines-left > .mikuia-navbar-links > a').hover(function onNavbarLinkHover() {
	if($('.mikuia-navbar-title-links > span[name="' + $(this).attr('name') + '"]').length > 0) {
		hideNavbarLinks()
		clearTimeout(navbarHideTimeout)
		$(this).addClass('selected')
		$('.mikuia-navbar-lines-left > .mikuia-navbar-title > span').hide()
		$('.mikuia-navbar-title-links > span[name="' + $(this).attr('name') + '"]').show()
	} else {
		hideNavbarLinks()
	}
})

$('.mikuia-navbar').hover(null, function() {
	navbarHideTimeout = setTimeout(function() {
		hideNavbarLinks()
	}, 3000)
})
