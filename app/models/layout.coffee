class Layout
  constructor: (@figure) ->
    @_buildElementTree()
    @_computeWidths()

  _buildElementTree: ->
    terminal = @figure.terminalComponent()

    @elements = []
    for c in terminal.topLevelComponents()
      el = new Element(c)
      el.populateChildren()
      @elements.push el

    @elements

  _computeWidths: ->
    for element in @elements
      element.computeWidth()

class Element
  constructor: (@component) ->

  populateChildren: ->
    @children = []

    for c in @component.immediatelyInteriorComponents()
      el = new Element(c)
      el.populateChildren()

      @children.push el

  computeWidth: ->
    element = this

    class WidthVisitor
      visitCombinator: ->
        # 1 for rhyme
        # 1 + children widths for rhythm
        childrenWidths = (child.computeWidth() for child in element.children)
        1 + childrenWidths.reduce ((t, s) -> t + s), 1

      visitApplicator: ->
        1

    visitor = new WidthVisitor
    @width = element.component.accept(visitor)

module.exports =
  layout: Layout
