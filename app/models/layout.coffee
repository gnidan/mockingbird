_ = require 'underscore'

class Layout
  constructor: (component=null) ->
    if component?
      return Layout.newLayoutForTopLevelComponent(component)
    else
      @columns = []

  @newLayoutForTopLevelComponent: (component) ->
    layout = new Layout
    layout.columns = Layout._columns(component.siblings())
    layout.width = sumColumnWidths(layout.columns)
    layout

  @_columns: (components) ->
    columns = []
    for c in components
      columns.push (replication = new Column) if c.out._to.length > 1
      columns.push Layout._componentColumn(c)
    columns

  @_componentColumn: (component) ->
    class ColumnMakingVisitor
      visitApplicator: (applicator) ->
        column = new Column(applicator)

      visitCombinator: (combinator) ->
        children = combinator.immediatelyInteriorComponents()
        leftWidth = if combinator.in.from is not null then 1 else 0

        layout = new Layout
        layout.columns.push (right = new Column)
        (layout.columns.push childColumn \
          for childColumn in Layout._columns(children))
        layout.columns.push (rhyme = new Column)
        layout.columns.push (left = new Column(null, null, width: leftWidth))
        
        layout.width = sumColumnWidths(layout.columns)

        outerColumn = new Column(combinator, layout, width: layout.width)

    visitor = new ColumnMakingVisitor
    column = component.accept(visitor)

class Column
  constructor: (@component=null, @layout=null, opts={}) ->
    @width = if opts.width? then opts.width else 1

sumColumnWidths = (columns) ->
  _.foldl(columns, ((acc, column) ->
    acc + column.width), 0)

module.exports =
  layout: Layout
