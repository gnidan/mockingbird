class Layout
  constructor: (@figure) ->
    @elements = []

  elementTree: () ->
    terminal = @figure.terminalComponent()

    tree = []
    for c in terminal.topLevelComponents()
      el = new Element(c)
      el.populateChildren()
      tree.push el

    tree

class Element
  constructor: (@component) ->

  populateChildren: ->
    @children = []

    for c in @component.immediatelyInteriorComponents()
      el = new Element(c)
      el.populateChildren()

      @children.push el

module.exports =
  layout: Layout
