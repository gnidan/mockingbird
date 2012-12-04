class Layout
  constructor: (component) ->
    @columns = (@_layoutIndividualComponent(sibling) for sibling in component.siblings())

class Column

module.exports =
  layout: Layout
