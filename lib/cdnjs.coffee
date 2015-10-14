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
      "cdnjs:get-url": => @GetUrl()
      "cdnjs:download-file": => @DownloadFile()

  GetUrl: ->
    @cdnjsView.toggle({action: 'url'})

  DownloadFile: ->
    @cdnjsView.toggle({action: 'download'})

  deactivate: ->
    @cdnjsView.destroy()

  serialize: ->
    cdnjsViewState: @cdnjsView.serialize()
