CdnjsView = require './cdnjs-view'
request = require 'superagent'
{CompositeDisposable} = require 'atom'

module.exports =
  cdnjsView: null

  activate: (state) ->
    @cdnjsView = new CdnjsView(state.cdnjsViewState)
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace',
      #"cdnjs:convert": => @convert()
      "cdnjs:GetUrl": => @GetUrl()
      "cdnjs:DownloadFile": => @DownloadFile()
      #"cdnjs:GetScriptTag": => @GetScriptTag()
      #"cdnjs:GetLinkTag": => @GetLinkTag()
  
  url: ->
    @cdnjsView.toggle()

  GetUrl: ->
    @cdnjsView.toggle()

  GetScriptTag: ->
    @cdnjsView.toggle()

  GetLinkTag: ->
    @cdnjsView.toggle()

  DownloadFile: ->
    @cdnjsView.toggle({action: 'download'})

  deactivate: ->
    @cdnjsView.destroy()

  serialize: ->
    cdnjsViewState: @cdnjsView.serialize()
