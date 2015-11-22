_ = require 'underscore-plus'
fs = require 'fs'
wget = require 'wget'
path = require 'path'
tmp = require 'tmp'
request = require 'superagent'
{$, $$, View, SelectListView} = require 'atom-space-pen-views'

module.exports =
class CdnjsView extends SelectListView

  @activate: ->
    new CdnjsView

  keyBindings: null
  libraries: null

  initialize: ->
    super

    @addClass('overlay from-top')

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

      @setItems(events)
    else
      request.get "https://api.cdnjs.com/libraries?atom", (error, res) =>
        # handle error on api request
        if error
          # show error
          atom.notifications.addError 'An error has ocurred',
            detail: "error getting libraries list, please try again later"
            dismissable: true

          # close panel
          @cancel()

          return

        if res.body.results
          libraries = res.body.results
          _.each libraries, (library) ->
            events.push
              eventDescription: library.name
              eventName: library.latest

          @setItems(events)
          @libraries = events

  serialize: ->
    # pass

  getFilterKey: ->
    'eventDescription'

  toggle: (options = {}) ->

    @editor = atom.workspace.getActiveTextEditor()
    @action = options.action || ''
    currentFilePath = @editor?.getPath()

    if @action == 'download'
      list = $('.tree-view-scroller')
      selectedEntry = list.find('.selected')[0]

    if !@editor and !selectedEntry
      @cancel()
      return

    if selectedEntry?
      entryEntity = selectedEntry.file || selectedEntry.directory
      @selectedPath = if selectedEntry.file then path.dirname(entryEntity.path) else entryEntity.path
    else if currentFilePath
      @selectedPath = path.dirname(currentFilePath)
    else
      @selectedPath = false

    if !@libraries
      @getLibraries()
    else
      @setItems(@libraries)

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
    @setItems([])
    @hide()

  confirmed: ({eventName, eventDescription}) ->
    @cancel()
    @setLoading('Please wait...')
    @show()

    if eventName == 'version'
      @libraryVersion = eventDescription
      assets = _.filter @library.assets, (asset) ->
        if asset.version == eventDescription
          return true

      assets = assets[0].files
      files = []
      _.each assets, (filename) ->
        files.push {eventName: 'file', eventDescription: filename}
      @setItems(files)
      @setLoading()
    else if eventName == 'file'
      url = '//cdnjs.cloudflare.com/ajax/libs/' + @library.name + '/' + @libraryVersion + '/' + eventDescription

      if @action == 'download'
        filePath = eventDescription.split('/')
        filePath = filePath[filePath.length-1]
        tmpObject = false

        if @selectedPath
          outputPath = "#{@selectedPath}/#{filePath}"
        #TODO: set allowed file extensions to download, show images on new tab.
        else if path.extname(filePath) in ['.css', '.js', '.txt', '.csv', '.json']
          tmpObject = tmp.fileSync()
          outputPath = tmpObject.name
        else
          @cancel()
          return

        download = wget.download("http:#{url}", outputPath, {})

        # handle download error
        download.on "error", () =>
          atom.notifications.addError 'An error has ocurred',
            detail: "error downloading library, please try again later"
            dismissable: true

          # close panel
          @cancel()

        download.on "end", (output) =>
          # show notification
          detail = "#{eventDescription} (#{@libraryVersion})"

          if !tmpObject
            detail += "\n#{output}"

          atom.notifications.addSuccess 'library successfully downloaded',
            detail: detail
            dismissable: true
            icon: "cloud-download"

          # check for tmp file
          if tmpObject
            fs.readFile output, 'utf-8', (err, data) =>
              if err
                throw err

              # insert asset content on editor and cleanup
              @editor.insertText(data)
              tmpObject.removeCallback()

          # close panel
          @cancel()
      else
        @editor.insertText(url)
        @cancel()
    else
      request.get "https://api.cdnjs.com/libraries/#{eventDescription}", (error, res) =>
        # handle error on api request
        if error
          # show error message
          atom.notifications.addError 'An error has ocurred',
            detail: "error getting library assets, please try again later"
            dismissable: true

          # close panel
          @cancel()

          return

        if res.body
          @library = res.body
          library = res.body
          versions = []
          _.each library.assets, (asset) ->
            versions.push
              eventDescription: asset.version
              eventName: 'version'

          @setItems(versions)
          @setLoading()
