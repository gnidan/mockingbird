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

  from: (node) ->
    @_from = node
    node.to(this)

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
    seen = []
    allNodes = @allConnectingNodes()
    for type, node of allNodes
      if node.component? and node.component not in seen
        seen.push node.component

    seen

  _compare: (other, seenBefore) ->
    for node in @nodes()
      mine = this[node]
      theirs = other[node]

      if mine._compare(theirs, seenBefore) == false
        return false

    return true

class Applicator extends Component
  _nodes: ['in', 'op', 'out']

class Combinator extends Component
  _nodes: ['in', 'out']

class Structure
  @match: (figure, archetype) ->
    fStructure = Structure.forFigure(figure)
    tStructure = Structure.forFigure(archetype)

    figureIds = (c.id for c in figure.components())
    archetypeIds = (c.id for c in archetype.components())

    if figureIds.length != archetypeIds.length
      return false

    start = figureIds[0]
    for tid in archetypeIds
      map = Structure._tryMap(start, tid, fStructure, tStructure)
      if map?
        return true

  @_tryMap: (start, tid, fStructure, tStructure, map={}) ->
    map = _.clone(map)
    map[start] = tid

    for type, nodeStructure of fStructure[start]
      toCompare = []
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


  @forFigure: (figure) ->
    components = figure.components()
    structure = {}

    for component in components
      structure[component.id] = Structure._componentStructure(component)

    structure

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
