import i18n from 'i18next'
import XHR from 'i18next-xhr-backend'
import Cache from 'i18next-localstorage-cache'
import LanguageDetector from 'i18next-browser-languagedetector'

i18n
	.use(XHR)
	.use(Cache)
	.use(LanguageDetector)
	.init({
		fallbackLng: 'en',
		ns: ['common', 'header'],
		defaultNS: 'common',
		debug: true,
		interpolation: {
			escapeValue: false
		},
		detection: {
			order: ['querystring', 'localStorage', 'navigator'],
			lookupQuerystring: 'lang',
			lookupLocalStorage: 'lang'
		}
	})

export default i18n