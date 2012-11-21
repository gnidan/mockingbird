test = require '../setup'
expect = require('chai').expect

Combinator = require('models/component').combinator
Applicator = require('models/component').applicator
LayoutController = require 'controllers/layout'

describe 'Layout Controller', ->
  it 'should layout a combinator', ->
    i = test.makeIdiotBird()

    controller = new LayoutController

#    layout = controller.layout(i)

#    elements = layout.elements
