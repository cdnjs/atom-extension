{View} = require 'atom'

module.exports =
class CdnjsView extends View
  @content: ->
    @div class: 'cdnjs overlay from-top', =>
      @div "The Cdnjs package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->
    atom.workspaceView.command "cdnjs:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    console.log "CdnjsView was toggled!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
