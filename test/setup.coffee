jsdom = require('jsdom').jsdom
global.document or= jsdom()
global.window   or= global.document.createWindow()
global.navigator =
  userAgent: 'WebKit'

Combinator = require('models/component').combinator
Applicator = require('models/component').applicator

module.exports =
  create: ->
    @_setup()
    this

  destroy: ->

  fail: ->
    throw new Error(arguments...)

  _setup: ->

  makeIdiotBird: ->
    #   _______
    #  |       |
    #  +-------+
    #  |_______|
    #      I
    
    i = new Combinator
    i.in.to i.out
    i

  makeMockingbird: ->
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

  makeKestrel: ->
    k = new Combinator
    box = new Combinator
    k.in.to box.out
    box.out.to k.out
    k

  makeKite: ->
    kite = new Combinator
    box = new Combinator
    box.in.to box.out
    box.out.to kite.out
    kite
