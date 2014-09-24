---
---
class @SimpleBehaviors

  constructor: ->
    @bindClickEvents()

  bindClickEvents: ->
    jQuery(document).on 'click', '[data-event-click]', (event) ->
      node = $(@)

      # Lazy instantiation of behavior context
      unless behaviorContext = node.data('behavior-context')
        node.data('behavior-context', new SimpleBehaviorContext(@))
        behaviorContext = node.data('behavior-context')

      behaviorContext.fireAction(node.data('event-click'), event)

  class SimpleBehaviorContext
    constructor: (@node) ->
      @behaviors = @resolveBehaviors()

    fireAction: (action, args...) ->
      for behavior in @behaviors
        if behavior[action]?
          behavior[action].apply(behavior, args)
          return

      console.warn "Unresolvable action: '#{action}' for SimpleBehaviorContext: ", @behaviors

    resolveBehaviors: ->
      behaviors = [window]

      _behaviors = jQuery(@node).parents('[data-behaviors]').map (index, item) -> jQuery(item).data('behaviors')
      _behaviors = _behaviors.toArray().reverse()

      for behavior in _behaviors
        if window[behavior]?
          behaviors.push(window[behavior])
        else
          console.warn "Unresolvable behavior: '#{behavior}' for node: ", @node

      behaviors.reverse()

window.BluthActions =
  checkBananaStandForMoney: (event) ->
    alert("There's always money here!")
  driveStairCar: (event) ->
    alert("Vroom!");

window.BusterActions =
  driveStairCar: (event) ->
    alert("Buster is driving the stair car, mother!");

jQuery ->
  new SimpleBehaviors()
