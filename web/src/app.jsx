import React from 'react'
import ReactDOM from 'react-dom'
import {applyRouterMiddleware, browserHistory, IndexRedirect, IndexRoute, Router, Route} from 'react-router'
import {useScroll} from 'react-router-scroll'

import './styles/app.scss'

import CommunityLayout from './layouts/Community'

import HomePage from './pages/Home'
import StreamsPage from './pages/Streams'
import LevelsPage from './pages/Levels'
import LevelsChannelPage from './pages/LevelsChannel'
import NotFoundPage from './pages/NotFoundPage'
import UserPage from './pages/User'
import UserLevelsPage from './pages/UserLevels'

ReactDOM.render(
	<Router history={browserHistory} render={applyRouterMiddleware(useScroll())}>
		<Route path="/" component={CommunityLayout}>
			<Route path="home" component={HomePage} />
			<Route path="streams" component={StreamsPage} />
			<Route path="levels/:username" component={LevelsChannelPage} />
			<Route path="levels" component={LevelsPage} />
			<Route path="user/:username" component={UserPage} />
			<Route path="user/:username/levels" component={UserLevelsPage} />
			<Route path="*" component={NotFoundPage} />

			<IndexRedirect to="/home" />
		</Route>
	</Router>
, document.getElementById('app'))