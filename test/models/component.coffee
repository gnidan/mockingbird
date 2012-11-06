test = require '../setup'
expect = require('chai').expect
_ = require 'underscore'

Component = require('models/component').component
Applicator = require('models/component').applicator
Combinator = require('models/component').combinator
Node = require('models/component').node
Structure = require('models/component').structure

makeIdiotBird = ->
  #   _______
  #  |       |
  #  +-------+
  #  |_______|
  #      I
  
  i = new Combinator
  i.in.to i.out
  i

makeMockingbird = ->
  #   _______
  #  |  /-.  |
  #  +-<--o--+
  #  |_______|
  #      w
  
  w = new Combinator
  a = new Applicator
  w.in.to a.in
  w.in.to a.op
  w.out.from a.out
  w

makeKestrel = ->
  k = new Combinator
  box = new Combinator
  k.in.to box.out
  box.out.to k.out
  k

makeKite = ->
  kite = new Combinator
  box = new Combinator
  box.in.to box.out
  box.out.to kite.out
  kite

describe 'Nodes', ->
  it 'should connect to other nodes', ->
    #       ,--> n2
    # n1 --+---> n3

    n1 = new Node
    n2 = new Node
    n3 = new Node

    n1.to n2
    n1.to n3

    expect(n2._from).to.equal n1
    expect(n3._from).to.equal n1

  it 'should connect from other nodes', ->
    n1 = new Node
    n2 = new Node
    
    n2.from n1
    
    expect(n1._to).to.include n2

  it 'should be able to remove to connections', ->
    n1 = new Node
    n2 = new Node
    n3 = new Node

    n1.to n2
    n1.removeTo n2
    n1.to n3

    expect(n1._to).to.include n3
    expect(n1._to).not.to.include n2
    expect(n1._to).to.have.length 1

    expect(n1._from).to.be.null
    
  describe 'connection search', ->
    it 'should return a list of one node when not connected', ->
      n = new Node
      allNodes = n.allConnectingNodes()
      expect(allNodes).to.include n
      expect(allNodes).to.have.length 1

    it 'should find all connecting nodes', ->
      #       ,--> n2
      # n1 --+---> n3

      n1 = new Node
      n2 = new Node
      n3 = new Node

      n1.to n2
      n1.to n3

      allNodes = n1.allConnectingNodes()
      expect(allNodes).to.include n1
      expect(allNodes).to.include n2
      expect(allNodes).to.include n3
      expect(allNodes).to.have.length 3

    it 'should not have duplicates in case of a 2-loop', ->
      # n1 ---> n2 -,
      #  ^----------'

      n1 = new Node
      n2 = new Node

      n1.to n2
      n2.to n1
      
      allNodes = n1.allConnectingNodes()
      expect(allNodes).to.include n1
      expect(allNodes).to.include n2
      expect(allNodes).to.have.length 2

    it 'should not have duplicates in case of a 3-loop', ->
      # n1 ---> n2 -,
      #  ^--- n3 <--'

      n1 = new Node
      n2 = new Node
      n3 = new Node

      n1.to n2
      n2.to n3
      n3.to n1
      
      allNodes = n1.allConnectingNodes()
      expect(allNodes).to.include n1
      expect(allNodes).to.include n2
      expect(allNodes).to.include n3
      expect(allNodes).to.have.length 3
      
describe 'Structure', ->
  beforeEach ->
    #   _______
    #  |  /-.  |
    #  +-<--o--+
    #  |_______|
    #
    @b = new Combinator
    @a = new Applicator
    @b.in.to @a.in
    @b.in.to @a.op
    @b.out.from @a.out

  it 'should have a node structure', ->
    structure = Structure._nodeStructure(@b.in)
    expected =
      to: [[@a.id, 'in'], [@a.id, 'op']]

    expect(structure).to.deep.equal expected

    outer = new Combinator
    @b.out.to outer.out

    structure = Structure._nodeStructure(@b.out)
    expected =
      from: [@a.id, 'out']
      to: [[outer.id, 'out']]

    expect(structure).to.deep.equal expected

  it 'should have a individual component structure', ->
    structure = Structure._componentStructure(@b)
    expected =
      in: Structure._nodeStructure(@b.in)
      out: Structure._nodeStructure(@b.out)

    expect(structure).to.deep.equal expected

  it 'should have a global structure', ->

    structure = Structure.forFigure(@b)
    expected = {}
    expected[@b.id] = Structure._componentStructure(@b)
    expected[@a.id] = Structure._componentStructure(@a)

    expect(structure).to.deep.equal expected

  it 'should be able to tell if two figures have the same structure', ->
    # check against some generators
    mystery = new Combinator
    mystery.in.to mystery.out

    idiot = makeIdiotBird()
    isIdiot = Structure.match(mystery, idiot)
    expect(isIdiot).to.be.true

    mockingbird = makeMockingbird()
    isMockingbird = Structure.match(@b, mockingbird)
    expect(isMockingbird).to.be.true

    # check two combinators configured differently
    kite1 = new Combinator
    box1 = new Combinator
    box1.in.to box1.out
    box1.out.to kite1.out

    kite2 = new Combinator
    box2 = new Combinator
    kite2.out.from box2.out
    box2.out.from box2.in

    kitesMatch = Structure.match(kite1, kite2)
    expect(kitesMatch).to.be.true

  it 'should say a figure has the same structure as itself', ->
    kite = makeKite()
    expect(Structure.match(kite, kite)).to.be.true

  it "should be able to copy a figure's structure", ->
    mockingbird = makeMockingbird()

    mockingbird2 = Structure.copy(mockingbird)

    for component in mockingbird2.components()
      expect(mockingbird.components()).not.to.include component

    expect(Structure.match(mockingbird, mockingbird2)).to.be.true

describe 'Components', ->
  beforeEach ->
    #   _______
    #  |  /-.  |
    #  +-<--o--+
    #  |_______|
    #
    @b = new Combinator
    @a = new Applicator
    @b.in.to @a.in
    @b.in.to @a.op
    @b.out.from @a.out

  it 'should have a hash of nodes', ->
    ids = (id for id, node of @b.nodes())
    nodes = (node for id, node of @b.nodes())

    expect(ids).to.include 'in'
    expect(ids).to.include 'out'
    expect(ids).to.have.length 2

  it 'should give their nodes a type', ->
    expect(@b.in.type).to.equal 'in'
    expect(@b.out.type).to.equal 'out'
    expect(@a.op.type).to.equal 'op'

  it 'should have a list of all connecting nodes', ->
    allNodes = @b.allConnectingNodes()
    expect(allNodes).to.include @b.in
    expect(allNodes).to.include @b.out
    expect(allNodes).to.include @a.in
    expect(allNodes).to.include @a.op
    expect(allNodes).to.include @a.out
    expect(allNodes).to.have.length 5

  it 'should have a list of nodes even if the graph is separated', ->
    #  _____________
    # |             |
    # |   _______   |
    # |  |  /-.  |  |
    # +  +-<--o--+--+
    # |  |_______|  |
    # |             |
    # |_____________|
    #
    outer = new Combinator
    @b.out.to outer.out

    allNodes = outer.allConnectingNodes()
    expect(allNodes).to.include @b.in
    expect(allNodes).to.include @b.out
    expect(allNodes).to.include @a.in
    expect(allNodes).to.include @a.op
    expect(allNodes).to.include @a.out
    expect(allNodes).to.include outer.in
    expect(allNodes).to.include outer.out
    expect(allNodes).to.have.length 7

  it 'should have a hash of components', ->
    components = @b.components()
    expect(components[@b.id]).to.equal @b
    expect(components[@a.id]).to.equal @a
    expect(_.keys(components)).to.have.length 2

  it 'should be able to create a new component of the same type', ->
    newB = @b.newComponent()
    expect(newB.in).to.exist
    expect(newB.out).to.exist
    expect(newB.op).not.to.exist

  describe 'beta reduction', ->
    it 'should perform beta-reduction on combinators', ->
      #  ______     _______
      # |      |   |   ,   |
      # +------+---+--'o---+
      # |______|   |_______|
      #          .
      #          .
      #          V
      #     ______   
      #    |      | ,--.
      #    +------+'---o---+
      #    |______|    

      left = makeIdiotBird()

      right = new Combinator
      appl = new Applicator
      right.in.to appl.in
      right.in.to appl.op
      appl.out.to right.out

      left.out.to right.in
      
      result = right.betaReduction()

      expect(left.out._to).to.include appl.in
      expect(left.out._to).to.include appl.op
      expect(left.out._to).to.have.length 2

      expect(appl.in._from).to.equal left.out
      expect(appl.op._from).to.equal left.out

      expect(appl.out._to).to.have.length 0

      expect(result.terminal).to.equal appl
      expect(result.type).to.equal 'beta-reduction'

  describe 'replication', ->
    it 'should find a split "to," copy the component, and rewire', ->
      #     ______   
      #    |      | ,--.
      #    +------+'---o---+
      #    |______|    
      #          .
      #          .
      #          V
      #      ______   
      #     |      |
      #     +------+---. 
      #     |______|   |
      #     ______     |
      #    |      |    |
      #    +------+----o---+
      #    |______|    

      left = makeIdiotBird()
      appl = new Applicator
      left.out.to appl.in
      left.out.to appl.op

      result = appl.replication()

      inComponent = appl.in._from.component
      opComponent = appl.op._from.component

      expect(inComponent).not.to.equal opComponent
      expect(Structure.match(inComponent, opComponent)).to.be.true

      expect(result.terminal).to.equal appl
      expect(result.type).to.equal 'replication'

    it 'should copy out specifically the most terminal node connection', ->
      #     ______   ,---.
      #    |      | ,-.  |
      #    +------+'--o--o-+
      #    |______|    
      #          .
      #          .
      #          V
      #      ______ 
      #     |      | 
      #     +------+-----.
      #     |______|     |
      #     ______       |
      #    |      | ,-.  |
      #    +------+'--o--o-+
      #    |______|    

      left = makeIdiotBird()
      a1 = new Applicator
      a2 = new Applicator
      a1.out.to a2.in
      left.out.to a2.op

      left.out.to a1.op
      left.out.to a1.in

      a2.replication()

      newIdiot = a2.op._from.component
      expect(left).to.not.equal newIdiot
      expect(newIdiot.out._to).to.include a2.op
      expect(left.out._to).not.to.include a2.op
      expect(left.out._to).to.have.length 2

  describe 'composition/reduction', ->
    it 'should find the terminal component', ->
      i = makeIdiotBird()
      w = makeMockingbird()
      i.out.to w.in

      terminal = i.terminalComponent()
      expect(terminal).to.equal w



    it 'should compose I and get itself', ->
      i = makeIdiotBird()

      result = i.reduce()

      expect(Structure.match(result, makeIdiotBird())).to.be.true

    it 'should compose II and get I', ->
      i1 = makeIdiotBird()
      i2 = makeIdiotBird()

      i1.out.to i2.in

      result = i2.reduce()
      expect(Structure.match(result, makeIdiotBird())).to.be.true

    it 'should compose wI and get I', ->
      i = makeIdiotBird()
      w = makeMockingbird()
      i.out.to w.in

      result = w.reduce()
      expect(Structure.match(result, makeIdiotBird())).to.be.true

    it 'should compose KI and get Kite', ->
      k = makeKestrel()
      i = makeIdiotBird()
      i.out.to k.in

      result = k.reduce()
      expect(Structure.match(result, makeKite())).to.be.true

    it 'should compose a (Kite)w and get an I', ->
      kite = makeKite()
      w = makeMockingbird()
      w.out.to kite.in

      result = kite.reduce()
      expect(Structure.match(result, makeIdiotBird())).to.be.true

    it 'should compose (Kw)KI and get a w', ->
      k = makeKestrel()
      w = makeMockingbird()
      ki = makeKite()

      w.out.to k.in
      kw = k.reduce()

      ki.out.to kw.in
      result = kw.reduce()

      expect(Structure.match(result, makeMockingbird())).to.be.true

