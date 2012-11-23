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

  accept: (visitor, args...) ->
    visitor.visitComponent(this, args...)

  fold: (f, acc, seen=[]) ->
    seen.push this
    acc = f(this, acc)

    nodes = _.values(@nodes())
    for node in nodes
      c = node._from?.component
      if c? and c not in seen
        acc = c.fold(f, acc, seen)

    acc

  components: ->
    f = (component, acc) ->
      acc[component.id] = component
      acc

    @fold f, {}

  componentTree: ->
    # backwards and forwards and backwards and forwards and upside down

    parentsHeightsChildren = (comp, acc) ->
      # find parent that will give component its maximum height
      #   - follows 'to' paths: going forward

      [p, h, c] = acc
      if comp.id in p
        return acc

      maxHeight = 0
      maxParent = null
      for destNode in comp.out._to
        [newP, newH, newC] = parentsHeightsChildren(destNode.component,
          [p, h, c])
        p = _.defaults(p, newP)
        h = _.defaults(h, newH)
        c = _.defaults(c, newC)

        if destNode.type is 'out'
          # if the destNode is an out node, we're inside a combinator
          # that combinator is our parent, and our height is that 
          # combinator's height + 1
          myP = destNode.component
          myH = h[destNode.component.id] + 1
        else
          # otherwise, we should have the same parent and height as that 
          # (sibling) node's component
          myP = p[destNode.component.id]
          myH = h[destNode.component.id]

        if myH > maxHeight
          maxParent = myP
          maxHeight = myH

      p = _.extend(p, _.object([[comp.id, maxParent]]))
      h = _.extend(h, _.object([[comp.id, maxHeight]]))

      if maxParent?
        parentsChildren = if maxParent.id of c and comp not in c[maxParent.id]
          c[maxParent.id].concat([comp])
        else
          [comp]

        c = _.defaults(_.object([[maxParent.id, parentsChildren]]), c)

      return [p, h, c]

    # this part goes backwards: we'll mostly calculate parents and 
    # heights on the way back, and then fill in the gaps going forward 
    # with parents()
    [p, h, c] = @fold(parentsHeightsChildren, [{}, {}, {}])
    c

  immediatelyInteriorComponents: ->
    components = @components()
    children = @componentTree()

    children[@id]

  terminalComponent: ->
    if @out._to.length == 0
      return this
    else
      return @out._to[0].component.terminalComponent()

  replication: ->
    for type, node of @nodes()
      sourceNode = node._from
      if sourceNode? and sourceNode._to.length > 1
        sourceNode.removeTo node
        Structure.copy(sourceNode.component).out.to node
        return {
          component: this
          type: 'replication'
        }

  reduce: ->
    results = []
    result = @reduceOnce()
    while result?
      results.push(result)
      result = result.component.reduceOnce()

    if results.length > 0
      return results[results.length - 1].component
    else
      return this

  reduceOnce: ->
    terminalComponent = @terminalComponent()

    return terminalComponent._doReduceOnce()

  _doReduceOnce: ->
    for type, node of _.omit(@nodes(), 'out')
      sourceNode = node._from
      result = sourceNode.component._doReduceOnce() if sourceNode?
      return result if result?

    result = @replication()
    return result if result?

  newComponent: ->
    return null

class Applicator extends Component
  _nodes: ['in', 'op', 'out']

  newComponent: ->
    new Applicator

  accept: (visitor, args...) ->
    visitor.visitApplicator(this, args...)

  substitution: ->
    operand = @in._from?.component
    operator = @op._from?.component

    if operand? and operator?
      operand.out.removeTo(@in)
      operator.out.removeTo(@op)

      operator.in.from operand.out

      return {
        component: operator
        type: 'substitution'
      }

  _doReduceOnce: ->
    result = super()
    return result if result?

    result = @substitution()
    return result

  immediatelyInteriorComponents: ->
    []

class Combinator extends Component
  _nodes: ['in', 'out']

  newComponent: ->
    new Combinator

  accept: (visitor, args...) ->
    visitor.visitCombinator(this, args...)

  betaReduction: ->
    leftside = @in._from?.component

    if leftside?
      leftside.out.removeTo(@in)

      for node in @in._to
        leftside.out.to node

      outFrom = @out._from
      outFrom.removeTo(@out)

      for node in @out._to
        outFrom.to node

      return {
        component: outFrom.component
        type: 'beta-reduction'
      }

  _doReduceOnce: ->
    result = super()
    return result if result?

    result = @betaReduction()
    return result

class Structure
  @forFigure: (figure) ->
    structure = {}
    for id, component of figure.components()
      structure[id] = Structure._componentStructure(component)
    structure

  @stringForFigure: (figure) ->
    structure = Structure.forFigure(figure)
    result = []
    for id, componentStructure of structure
      result.push "#{id}:"
      for type, nodeStructure of componentStructure
        result.push "  #{type}:"

        if nodeStructure.from
          connection = Structure._stringForConnection(nodeStructure.from)
          result.push "    from: #{connection}"
        if nodeStructure.to
          connections = []
          for connection in nodeStructure.to
            connStr = Structure._stringForConnection(connection)
            connections.push connStr
          result.push "    to: [#{connections.join(', ')}]"

    "#{result.join('\n')}\n"

  @_stringForConnection: (connection) ->
    "<#{connection[0]}, #{connection[1]}>"

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
    storedTo = figure.out._to
    figure.out._to = []
    structure = Structure.forFigure(figure)
    components = figure.components()

    figureIds = (c.id for i, c of components)

    map = Structure._setupConnections(figure.id, structure, components)

    figure.out._to = storedTo
    map[figure.id]

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
