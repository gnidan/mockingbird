test = require '../setup'
expect = require('chai').expect

Combinator = require('models/component').combinator
Applicator = require('models/component').applicator

Layout = require('models/layout').layout

describe 'Layout', ->
  it 'should make a column for an applicator', ->
    a = new Applicator
    layout = new Layout(a)
    column = layout._layoutIndividualComponent(a)

    expect(column.component).to.equal a
    expect(column.layout).to.be.null

  it 'should make a column for a combinator', ->
    b = new Combinator
    layout = new Layout(b)
    column = layout._layoutIndividualComponent(b)

    expect(column.component).to.equal b
    expect(column.layout).to.not.be.null

  it 'should make columns for components with siblings', ->
    b1 = new Combinator
    b2 = new Combinator
    b3 = new Combinator
    b2.out.to b1.in
    b3.out.to b2.in

    layout = new Layout(b1)
    expect(layout.columns[0].component).to.equal b1
    expect(layout.columns[1].component).to.equal b2
    expect(layout.columns[2].component).to.equal b3
    expect(layout.columns).to.have.length 3

  it 'should have a width', ->
    i = test.makeIdiotBird()
    layout = new Layout(i)
    expect(layout.width).to.equal 2

    a = new Applicator
    layout = new Layout(a)
    expect(layout.width).to.equal 1

    w = test.makeMockingbird()
    layout = new Layout(w)
    expect(layout.width).to.equal 3

    l = test.makeLark()
    layout = new Layout(l)
    expect(layout.width).to.equal 6

