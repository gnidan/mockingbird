test = require '../setup'
expect = require('chai').expect

Combinator = require('models/component').combinator

Layout = require('models/layout').layout
Element = require('models/layout').element

describe 'Layout', ->
  it 'should generate an element tree', ->
    lark = test.makeLark()
