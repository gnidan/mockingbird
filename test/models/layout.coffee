test = require '../setup'
expect = require('chai').expect

Combinator = require('models/component').combinator
Applicator = require('models/component').applicator

Layout = require('models/layout').layout
Element = require('models/layout').element

describe 'Layout', ->
  it 'should generate an element tree', ->
    lark = test.makeLark()

    layout = new Layout(lark)
    elTree = layout.elements

    # [larkElement]
    #   |
    #   '-> [innerElement]
    #         |
    #         '-> [leftElement, rightElement]

    expect(elTree).to.have.length 1
    expect(elTree[0].children).to.have.length 1
    expect(elTree[0].children[0].children).to.have.length 2

  it 'should generate an element tree for multiple connected combinators', ->
    i = test.makeIdiotBird()
    w = test.makeMockingbird()
    l = test.makeLark()

    i.out.to w.in
    w.out.to l.in

    layout = new Layout(l)
    elTree = layout.elements

    expect(elTree).to.have.length 3

    l = elTree[0]
    w = elTree[1]
    i = elTree[2]

    expect(i.children).to.have.length 0

    expect(w.children).to.have.length 1
    expect(w.children[0].children).to.have.length 0

    expect(l.children).to.have.length 1
    expect(l.children[0].children).to.have.length 2

  it 'should calculate the width of an element', ->
    i = test.makeIdiotBird()
    layout = new Layout(i)
    expect(layout.elements[0].width).to.equal 2

    a = new Applicator
    layout = new Layout(a)
    expect(layout.elements[0].width).to.equal 1

    w = test.makeMockingbird()
    layout = new Layout(w)
    expect(layout.elements[0].width).to.equal 3

    l = test.makeLark()
    layout = new Layout(l)
    expect(layout.elements[0].width).to.equal 6

  it 'should calculate the height of an element', ->
    i = test.makeIdiotBird()
    layout = new Layout(i)
    expect(layout.elements[0].height).to.equal 2

    a = new Applicator
    layout = new Layout(a)
    expect(layout.elements[0].height).to.equal 1

    w = test.makeMockingbird()
    layout = new Layout(w)
    expect(layout.elements[0].height).to.equal 3

    l = test.makeLark()
    layout = new Layout(l)
    expect(layout.elements[0].height).to.equal 6
