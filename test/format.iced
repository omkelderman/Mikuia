should = require 'should'
formatter = new (require('../core/Format').Format)
format = (str, o = {}) -> formatter.parse str, o

describe 'Format', ->
	it 'should do nothing for simple cases', ->
		format('hey you').should.equal 'hey you'

	describe 'new format', ->
		it 'should allow mixed expressions', ->
			format('foo {{"bar"}} baz').should.equal 'foo bar baz'

		it 'should parse expressions', ->
			format('{{ 2 }}').should.equal '2'

		it 'should parse math expressions', ->
			format('{{ 2 + 2 }}').should.equal '4'

		it 'should know about defined variables', ->
			format('{{ a + b }}', a: 5, b: 6).should.equal '11'

		it 'should find defined functions', ->
			format('{{ inc(a) }}', a: 5, inc: (x) -> x + 1).should.equal '6'

		it 'should forget previously declared variables and functions', ->
			format('{{ inc(a + b) }}').should.equal '(error)'

	describe 'old format', ->
		it 'should still work', ->
			format('<%variable%>', variable: 'Hello').should.equal 'Hello'

		it 'should run functions', ->
			format('<%round2/variable%>', variable: 3.14159).should.equal '3.14'

		it 'should run multiple functions correctly', ->
			format('<%round/commas/variable%>', variable: '1234567.89').should.equal '1,234,568'

	describe 'stock functions', ->
		it 'should ceil', ->
			format('{{ ceil(13.37) }}').should.equal '14'

		it 'should add commas', ->
			format('{{ commas(1234567) }}').should.equal '1,234,567'

		it 'should floor', ->
			format('{{ floor(6.9) }}').should.equal '6'

		it 'should round', ->
			format('{{ round(3.14) }}').should.equal '3'
			format('{{ round(6.9) }}').should.equal '7'

		it 'should round with a 1 decimal place precision', ->
			format('{{ round1(3.14159) }}').should.equal '3.1'

		it 'should round with a 2 decimal place precision', ->
			format('{{ round2(3.14159) }}').should.equal '3.14'

		it 'should round with a 3 decimal place precision', ->
			format('{{ round3(3.14159) }}').should.equal '3.142'

		it 'should round with a 4 decimal place precision', ->
			format('{{ round4(3.14159) }}').should.equal '3.1416'

		it 'should round with custom amount of decimal places', ->
			format('{{ round(12.3456789, 3) }}').should.equal '12.346'

		it 'should make sure strings are converted to numbers', ->
			format('{{ round2(string) }}', string: "3.14159").should.equal '3.14'

		it 'should convert strings to lowercase', ->
			format('{{ lower("Hello") }}').should.equal 'hello'
			
		it 'should convert strings to uppercase', ->
			format('{{ upper("hello") }}').should.equal 'HELLO'