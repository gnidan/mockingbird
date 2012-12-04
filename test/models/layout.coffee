test = require '../setup'
expect = require('chai').expect

Combinator = require('models/component').combinator
Applicator = require('models/component').applicator

Layout = require('models/layout').layout

describe 'Layout', ->
  describe 'columns', ->
    it 'should make a column for an applicator', ->
      a = new Applicator
      column = Layout._componentColumn(a)

      expect(column.component).to.equal a
      expect(column.width).to.equal 1
      expect(column.layout).to.be.null

    it 'should make columns for components with siblings', ->
      a1 = new Applicator
      a2 = new Applicator
      a3 = new Applicator
      a2.out.to a1.in
      a3.out.to a2.in

      layout = new Layout(a1)
      expect(layout.columns[0].component).to.equal a1
      expect(layout.columns[1].component).to.equal a2
      expect(layout.columns[2].component).to.equal a3
      expect(layout.columns).to.have.length 3
      expect(layout.width).to.equal 3

    it 'should make a column for a combinator, with a layout', ->
      b = new Combinator
      column = Layout._componentColumn(b)

      expect(column.component).to.equal b
      expect(column.layout).to.not.be.null

      # right, rhyme, left
      expect(column.layout.columns).to.have.length 3
      expect(column.layout.columns[0].width).to.equal 1
      expect(column.layout.columns[1].width).to.equal 1
      expect(column.layout.columns[2].width).to.equal 0

    it 'should have columns for replicators not part of rhymes', ->
      a1 = new Applicator
      a2 = new Applicator

      a2.out.to a1.in
      a2.out.to a1.op

      layout = new Layout(a1)
      expect(layout.columns).to.have.length 3
      expect(layout.columns[0].component).to.equal a1
      expect(layout.columns[1].component).to.be.null
      expect(layout.columns[2].component).to.equal a2
      expect(layout.width).to.equal 3

  describe 'width', ->
    it 'should be correct for combinators in normal form', ->
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

    it 'should be correct for combinators not in normal form', ->
      b1 = new Combinator
      b2 = new Combinator
      a1 = new Applicator
      a2 = new Applicator
      b1.in.to a1.op
      b1.in.to a2.op
      b2.in.to a2.in
      b2.out.from a2.out
      b2.out.to a1.in
      a1.out.to b1.out

      layout = new Layout(b1)
      expect(layout.width).to.equal 6

      outer = new Combinator
      i = test.makeIdiotBird()
      a = new Applicator

      i.out.to a.in
      i.out.to a.op
      a.out.to outer.out

      layout = new Layout(outer)
      expect(layout.width).to.equal 6

