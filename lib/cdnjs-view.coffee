{View} = require 'atom'
_ = require 'underscore-plus'
{$, $$, SelectListView} = require 'atom'

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
  toggle: ->

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

  confirmed: ({eventName}) ->
    @cancel()
    @eventElement.trigger(eventName)

  attach: ->
    @storeFocusedElement()

    if @previouslyFocusedElement[0] and @previouslyFocusedElement[0] isnt document.body
      @eventElement = @previouslyFocusedElement
    else
      @eventElement = atom.workspaceView
    @keyBindings = atom.keymap.findKeyBindings(target: @eventElement[0])

    events = [{eventDescription: 'asdas', eventName: 'asdawewe'}]
    request.get "http://api.cdnjs.com/libraries", (res) =>
      if res.body.results
        libraries = res.body.results
        _.each libraries, (library) ->
          events.push
            eventDescription: library.name
            eventName: library.name

          return

        @setItems(events)

        atom.workspaceView.append(this)
        @focusFilterEditor()
      else
        #throw error

      return
