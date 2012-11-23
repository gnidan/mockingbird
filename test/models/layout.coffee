test = require '../setup'
expect = require('chai').expect

Combinator = require('models/component').combinator

Layout = require('models/layout').layout
Element = require('models/layout').element

describe 'Layout', ->
  it 'should generate an element tree', ->
    lark = test.makeLark()

    layout = new Layout(lark)
    elTree = layout.elementTree()

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
    elTree = layout.elementTree()

    expect(elTree).to.have.length 3

    l = elTree[0]
    w = elTree[1]
    i = elTree[2]

    expect(i.children).to.have.length 0

    expect(w.children).to.have.length 1
    expect(w.children[0].children).to.have.length 0

    expect(l.children).to.have.length 1
    expect(l.children[0].children).to.have.length 2
