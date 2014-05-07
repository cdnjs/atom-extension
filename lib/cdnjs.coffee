CdnjsView = require './cdnjs-view'
request = require 'superagent'

module.exports =
  cdnjsView: null

  activate: (state) ->
    @cdnjsView = new CdnjsView(state.cdnjsViewState)
    atom.workspaceView.command "cdnjs:convert", => @convert()

  convert: ->
    editor = atom.workspace.activePaneItem

    request.get "http://api.cdnjs.com/libraries", (res) ->
      if res.body.results
        libraries = res.body.results
        editor.insertText JSON.stringify(libraries[0])

      else
        #throw error

      return

  deactivate: ->
    @cdnjsView.destroy()

  serialize: ->
    cdnjsViewState: @cdnjsView.serialize()
