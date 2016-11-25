import React from 'react'

import {Alert, Col, Grid, Row} from 'react-bootstrap'
import {Interpolate, translate} from 'react-i18next'

var Guide = React.createClass({

	componentDidMount: function() {
		this.props.setHeaderOption('title', [this.props.t('header:link.guide')])
	},

	render: function() {
		const {t} = this.props
		return (
			<div>
				<Grid>
					<Row>
						<Col md={12}>
							<h1>{t('guide:title')}</h1>
							<Alert bsStyle="danger">
								<Interpolate i18nKey='guide:alert' useDangerouslySetInnerHTML={true} />
							</Alert>

							<h2>{t('guide:toc.title')}</h2>
							<br />
							<a href="#guide-what">{t('guide:toc.questions.what')}</a>
							<br />
							<a href="#guide-how">{t('guide:toc.questions.how')}</a>
							<br />
							<a href="#guide-commands">{t('guide:toc.questions.commands')}</a>
							<br />
							<a href="#guide-games">{t('guide:toc.questions.games')}</a>
							<br />
							<a href="#guide-no">{t('guide:toc.questions.no')}</a>
							<br />

							<hr />

							<div id="guide-what">
								<h1>{t('guide:toc.questions.what')}</h1>
								<p><Interpolate i18nKey='guide:toc.answers.what' useDangerouslySetInnerHTML={true} /></p>
							</div>

							<div id="guide-how">
								<h1>{t('guide:toc.questions.how')}</h1>
								<p><Interpolate i18nKey='guide:toc.answers.how' useDangerouslySetInnerHTML={true} /></p>
							</div>

							<div id="guide-commands">
								<h1>{t('guide:toc.questions.commands')}</h1>
								<p><Interpolate i18nKey='guide:toc.answers.commands' useDangerouslySetInnerHTML={true} /></p>
							</div>

							<div id="guide-games">
								<h1>{t('guide:toc.questions.games')}</h1>
								<p><Interpolate i18nKey='guide:toc.answers.games' useDangerouslySetInnerHTML={true} /></p>
							</div>

							<div id="guide-no">
								<h1>{t('guide:toc.questions.no')}</h1>
								<p><Interpolate i18nKey='guide:toc.answers.no' useDangerouslySetInnerHTML={true} /></p>
							</div>

							<hr />

							<p><Interpolate i18nKey='guide:whatever' useDangerouslySetInnerHTML={true} /></p>

						</Col>
					</Row>
				</Grid>
			</div>
		)
	}

})

export default translate('guide', {wait: true})(Guide)