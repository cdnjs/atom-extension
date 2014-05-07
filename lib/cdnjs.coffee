CdnjsView = require './cdnjs-view'

module.exports =
  cdnjsView: null

  activate: (state) ->
    #@cdnjsView = new CdnjsView(state.cdnjsViewState)
    atom.workspaceView.command "cdnjs:convert", => @convert()

  convert: ->
    editor = atom.workspace.activePaneItem
    editor.insertText('Hello cdnjs')

  deactivate: ->
    @cdnjsView.destroy()

  serialize: ->
    cdnjsViewState: @cdnjsView.serialize()
