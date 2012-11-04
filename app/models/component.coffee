_ = require 'underscore'

class Node
  @_lastId = 1000
  @_newId: ->
    @_lastId += 1
    @_lastId

  constructor: (@component, @type) ->
    @_from = null
    @_to = []
    @id = Node._newId()

  to: (node) ->
    node._from = this
    unless node in @_to
      @_to.push node

  removeTo: (node) ->
    @_to = _.without(@_to, node)
    node.from null

  from: (node) ->
    @_from = node
    node.to(this) if node?

  toString: ->
    from = if @_from? then @_from.id else 'null'
    to = (to.id for to in @_to)
      
    "<#{@id} from: #{from} to: [#{to}]>"

  allConnectingNodes: (seen = []) ->
    newNodes = [this]

    if @_from? and @_from not in newNodes.concat(seen)
      fromConnections = @_from.allConnectingNodes(newNodes.concat(seen))
      newNodes = newNodes.concat fromConnections

    for to in @_to
      if to not in newNodes.concat(seen)
        toConnections = to.allConnectingNodes(newNodes.concat(seen))
        newNodes = newNodes.concat toConnections

    if @component?
      for type, node of @component.nodes()
        unless node in newNodes.concat(seen)
          otherNodeConnections = node.allConnectingNodes(newNodes.concat(seen))
          newNodes = newNodes.concat otherNodeConnections

    return newNodes

  _compare: (other, seenBefore) ->
    from = @_compareFrom(other, seenBefore)
    return from
    
    # check to

  _compareFrom: (other, seenBefore) ->
    if @_from in seenBefore
      return true

    if @_from? and not other._from? or other._from? and not @_from?
      return false
    else if @_from == null
      return true

    seenBefore.push @_from
    @_from.component._compare(other._from.component, seenBefore)


class Component
  # ID generation class stuff
  @_lastId = 500
  @_newId: ->
    @_lastId += 1
    @_lastId

  _nodes: []

  constructor: ->
    @id = Component._newId()

    for type in @_nodes
      this[type] = new Node(this, type)
  
  nodes: ->
    _.pick(this, @_nodes)

  allConnectingNodes: ->
    seen = []

    for type, node of @nodes()
      unless node in seen
        seen = seen.concat node.allConnectingNodes(seen)

    seen

  components: ->
    seen = {}
    allNodes = @allConnectingNodes()
    for type, node of allNodes
      if node.component? and node.component.id not of seen
        seen[node.component.id] = node.component

    seen

  terminalComponent: ->
    for i, c of @components()
      if c.out._to.length == 0
        return c

  reduce: ->
    return
  
  newComponent: ->
    return

  _compare: (other, seenBefore) ->
    for node in @nodes()
      mine = this[node]
      theirs = other[node]

      if mine._compare(theirs, seenBefore) == false
        return false

    return true

class Applicator extends Component
  _nodes: ['in', 'op', 'out']

  newComponent: ->
    new Applicator

  reduce: ->
    leftside = @in._from?.component
    topside = @op._from?.component
    if leftside? and topside?
      leftside.reduce()
      topside.reduce()

      leftside.out.removeTo(@in)
      topside.out.removeTo(@op)

      topside.in.from leftside.out

      topside.reduce()

      if @out._to.length > 0
        for i in [0 .. @out._to.length - 1]
          if i is 0
            topside.out.to @out._to[i]
          else
            Structure.copy(topside).out.to @out._to[i]

      for to in @out._to
        @out.removeTo(to)

      delete this
      return topside

    else
      return this

class Combinator extends Component
  _nodes: ['in', 'out']

  newComponent: ->
    new Combinator

  reduce: ->
    leftside = @in._from?.component
    if leftside?
      leftside.reduce()

      leftside.out.removeTo(@in)

      if @in._to.length > 0
        for i in [0 .. @in._to.length - 1]
          if i is 0
            leftside.out.to @in._to[i]
          else
            Structure.copy(leftside).out.to @in._to[i]

      outFrom = @out._from
      outFrom.removeTo(@out)

      outFrom.component.reduce()

      delete this
      return outFrom.component
    else
      return this
      
class Structure
  @forFigure: (figure) ->
    structure = {}
    for id, component of figure.components()
      structure[id] = Structure._componentStructure(component)
    structure

  @match: (figure, archetype) ->
    fStructure = Structure.forFigure(figure)
    tStructure = Structure.forFigure(archetype)

    figureIds = (c.id for i, c of figure.components())
    archetypeIds = (c.id for i, c of archetype.components())

    if figureIds.length != archetypeIds.length
      return false

    start = figureIds[0]
    for tid in archetypeIds
      map = Structure._tryMap(start, tid, fStructure, tStructure)
      if map?
        return true

  @copy: (figure) ->
    structure = Structure.forFigure(figure)
    components = figure.components()
    terminal = figure.terminalComponent()

    figureIds = (c.id for i, c of components)

    start = terminal.id
    map = Structure._setupConnections(start, structure, components)

    map[terminal.id]

  @_setupConnections: (cid, structure, components, map = {}) ->
    componentStructure = structure[cid]

    if cid not of map
      newComponent = components[cid].newComponent()
      map[cid] = newComponent

    for type, nodeStructure of componentStructure
      for direction, dest of nodeStructure
        if direction == 'from'
          [destComponentId, destType] = dest

          if destComponentId not of map
            Structure._setupConnections(destComponentId, structure,
              components, map)

          map[cid][type].from map[destComponentId][destType]

    return map

  @_tryMap: (start, tid, fStructure, tStructure, map={}) ->
    map = _.clone(map)
    map[start] = tid

    for type, nodeStructure of fStructure[start]
      for direction, dest of nodeStructure
        if type not of tStructure[tid]
          return null

        if direction not of tStructure[tid][type]
          return null

        # we can ignore the to's because to's in a figure will be 
        # covered by matching from
        if direction == 'from'
          [destComponentId, destType] = dest
          [otherCid, otherType] = tStructure[tid][type][direction]


          if destType != otherType
            return null
          
          if destComponentId of map and map[destComponentId] != otherCid
            return null

          if destComponentId not of map
            map = Structure._tryMap(destComponentId, otherCid,
              fStructure, tStructure, map)
            if map is null
              return null

    return map


  @_componentStructure: (component) ->
    nodeStructure = {}

    for type, node of component.nodes()
      nodeStructure[type] = Structure._nodeStructure(node)

    nodeStructure

  @_nodeStructure: (node) ->
    nodeStructure = {}

    from = node._from
    nodeStructure.from = [from.component.id, from.type] if from?

    if node._to.length > 0
      nodeStructure.to = ([to.component.id, to.type] for to in node._to)

    nodeStructure


module.exports =
  component: Component
  applicator: Applicator
  combinator: Combinator
  node: Node
  structure: Structure
