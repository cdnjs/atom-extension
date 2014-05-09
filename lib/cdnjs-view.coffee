{View} = require 'atom'
_ = require 'underscore-plus'
fs = require 'fs'
{$, $$, SelectListView} = require 'atom'
wget = require 'wget'

request = require 'superagent'
module.exports =
class CdnjsView extends SelectListView

  @activate: ->
    new CdnjsView

  keyBindings: null

  initialize: ->
    super

    @addClass('command-palette overlay from-top')


  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()
  getFilterKey: ->
    'eventDescription'
  toggle: (options = {}) ->
    @action = options.action || ''
    if @action == 'download'
      list = $('.tree-view-scroller')
      selectedEntry = list.find('.selected')?.view()
      @selectedPath = selectedEntry.getPath()

    if @hasParent()
      @cancel()
    else
      @attach()
    #console.log "CdnjsView was toggled!"
    #if @hasParent()
      #@detach()
    #else
      #atom.workspaceView.append(this)

  viewForItem: ({eventName, eventDescription}) ->
    keyBindings = @keyBindings
    $$ ->
      @li class: 'event', 'data-event-name': eventName, =>
        @div class: 'pull-right', =>
          for binding in keyBindings when binding.command is eventName
            @kbd _.humanizeKeystroke(binding.keystrokes), class: 'key-binding'
        @span eventDescription, title: eventName

  confirmed: ({eventName, eventDescription}) ->
    #@cancel()
    @filterEditorView.getEditor().setText('')

    @setItems([])
    if eventName == 'version'
      @libraryVersion = eventDescription
      assets = _.filter @library.assets, (asset) ->
        if asset.version == eventDescription
          return true

      assets = assets[0].files
      files = []
      _.each assets, (file) ->
        files.push {eventName: 'file', eventDescription: file}
      @setItems(files)
    else if eventName == 'file'
      editor = atom.workspace.activePaneItem
      url = '//cdnjs.cloudflare.com/ajax/libs/' + @library.name + '/' + @libraryVersion + '/' + eventDescription
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

        else
          #throw error

        return
    #@eventElement.trigger(eventName)
  attach: ->
    @storeFocusedElement()

    if @previouslyFocusedElement[0] and @previouslyFocusedElement[0] isnt document.body
      @eventElement = @previouslyFocusedElement
    else
      @eventElement = atom.workspaceView
    @keyBindings = atom.keymap.findKeyBindings(target: @eventElement[0])
    events = []
    if @libraries
      _.each @libraries, (library) ->
        events.push
          eventDescription: library.name
          eventName: library.latest

        return

      @setItems(events)

      atom.workspaceView.append(this)
      @focusFilterEditor()
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

          atom.workspaceView.append(this)
          @focusFilterEditor()
        else
          #throw error

        return
