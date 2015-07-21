_ = require 'underscore-plus'
fs = require 'fs'
{$, $$, View, SelectListView} = require 'atom-space-pen-views'
wget = require 'wget'

request = require 'superagent'
module.exports =
class CdnjsView extends SelectListView

  @activate: ->
    new CdnjsView

  keyBindings: null

  initialize: ->
    super

    @addClass('overlay from-top')
    @getLibraries()
  
  destroy: ->
    @detach()

  getLibraries: ->
    events = []

    @setLoading('Please wait...')
    @storeFocusedElement()

    if @previouslyFocusedElement[0] and @previouslyFocusedElement[0] isnt document.body
      @eventElement = @previouslyFocusedElement
    else
      @eventElement = atom.views.getView(atom.workspace)

    @keyBindings = atom.keymaps.findKeyBindings(target: @eventElement[0])

    if @libraries
      _.each @libraries, (library) ->
        events.push
          eventDescription: library.name
          eventName: library.latest

        return

      @setItems(events)
      @show()
    else
      request.get "http://api.cdnjs.com/libraries?atom", (res) =>
        if res.body.results
          @libraries = res.body.results
          _.each @libraries, (library) ->
            events.push
              eventDescription: library.name
              eventName: library.latest

            return

          @setItems(events)
          @show()
        else
          #throw error

        return

  serialize: ->

  getFilterKey: ->
    'eventDescription'
  
  toggle: (options = {}) ->
    @action = options.action || ''
    if @action == 'download'
      list = $('.tree-view-scroller')
      selectedEntry = list.find('.selected')?.view()
      @selectedPath = selectedEntry.getPath()

    if @hasParent()
      @getLibraries()

    if !@panel?.isVisible()
      @show()

  show: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()

    @storeFocusedElement()
    @focusFilterEditor()

  hide: ->
    @panel?.hide()

  viewForItem: ({eventName, eventDescription}) ->
    keyBindings = @keyBindings
    $$ ->
      @li class: 'event', 'data-event-name': eventName, =>
        @div class: 'pull-right', =>
          for binding in keyBindings when binding.command is eventName
            @kbd _.humanizeKeystroke(binding.keystrokes), class: 'key-binding'
        @span eventDescription, title: eventName

  cancelled: ->
    @hide()

  confirmed: ({eventName, eventDescription}) ->
    @cancel()
    @setLoading('Please wait...')
    @show()
    
    editor = atom.workspace.getActiveTextEditor()

    if eventName == 'version'
      @libraryVersion = eventDescription
      assets = _.filter @library.assets, (asset) ->
        if asset.version == eventDescription
          return true

      assets = assets[0].files
      files = []
      _.each assets, (file) ->
        files.push {eventName: 'file', eventDescription: file.name}
      @setItems(files)
      @setLoading()
    else if eventName == 'file'
      url = 'https://cdnjs.cloudflare.com/ajax/libs/' + @library.name + '/' + @libraryVersion + '/' + eventDescription
      if @action == 'download'
        filePath = eventDescription.split('/')
        filePath = filePath[filePath.length-1]
        download = wget.download('http:' + url, @selectedPath + "/" + filePath, {})
        download.on "end", (output) ->
          console.log output
          return

        #request.get('http:' + url).set("Accept", "text/plain").end (error, res) =>
          #console.log res
          #fs.writeFile @selectedPath + "/" + eventDescription, res.text, 'utf8', (err) ->

            #throw err  if err
            #console.log "It's saved!"
            #return
      else
        editor.insertText(url)
        @cancel()
    else
      request.get "http://api.cdnjs.com/libraries/" + eventDescription, (res) =>

        if res.body
          @library = res.body
          library = res.body
          versions = []
          _.each library.assets, (asset) ->
            versions.push
              eventDescription: asset.version
              eventName: 'version'

            return

          @setItems(versions)
          @setLoading()

        else
          #throw error

        return
    #@eventElement.trigger(eventName)
