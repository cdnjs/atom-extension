CdnjsView = require './cdnjs-view'
request = require 'superagent'

module.exports =
  cdnjsView: null

  activate: (state) ->
    @cdnjsView = new CdnjsView(state.cdnjsViewState)
    atom.workspaceView.command "cdnjs:convert", => @convert()
    atom.workspaceView.command "cdnjs:GetUrl", => @GetUrl()
    atom.workspaceView.command "cdnjs:GetScriptTag", => @GetScriptTag()
    atom.workspaceView.command "cdnjs:GetLinkTag", => @GetLinkTag()

  url: ->
    @cdnjsView.toggle()

  GetUrl: ->
    @cdnjsView.toggle()

  GetScriptTag: ->
    @cdnjsView.toggle()

  GetLinkTag: ->
    @cdnjsView.toggle()

  deactivate: ->
    @cdnjsView.destroy()

  serialize: ->
    cdnjsViewState: @cdnjsView.serialize()
