---
layout: post
title:  "Live-updating Rails with React.js & Pusher"
date:   2014-09-23 15:47:33
author: Robert Mosolgo
header: /assets/images/check-ins-logo.png
team:   web
---

Originally, PCO Check-Ins was a Batman.js app. When we rewrote it, Flux-inspired React.js turned out to be very conductive to our live-updating interface.

<img src="/assets/images/check-ins-dashboard.png" />

The process looks like this:

- Relevant models have an `after_commit` hook that registers any change
- In an `ApplicationController` `after_filter`, registered changes are emitted over Pusher
- In the browser, the singleton `PusherStore` picks up the event and fires change events for each model that changed
- Mounted React components respond to change events however they should

For this pattern, I'm indebted to previous work on PCO Resources and PCO Check-Ins. Jeff, Zack and Dan fine-tuned a system we called `Batman::Live` which performed _much more extensive_ live-updating. It tracked creates, updates and destroys and propagated these events to Batman.js on all clients.

# Tracking Changes on the Server

I implemented `ChangedModelList` with a simple API:

- `.restart!`: Prepare to gather some changes
- `.changed(record)`: Register `record` as having been changed
- `.fire!`: Send any changes over the wire by Pusher

```ruby
class ChangedModelList
  include HasCurrentInstance # provides Thread-safe `.current=`/`.current`

  attr_accessor :records

  def self.restart!
    self.current = self.new
  end

  def self.changed(some_record)
    if current.present?
      current.records[some_record.class.name][some_record.id] = some_record.as_json
    else
      Rails.logger.debug "Didn't register change for #{some_record.class.name} because it was outside the request cycle"
    end
  end

  def self.fire!
    self.current.fire!
  end

  def initialize
    self.records = Hash.new { |hash, key| hash[key] = {} }
  end

  def fire!
    if self.records.keys.any?
      Pusher.trigger(channel, "records_changed", {records: self.records})
    end
    self.records = nil
    self.class.current = nil
  end

  private

  def channel
    Organization.current.pusher_channel
  end
end
```

Then, I integrated it with models by the `FiresChangeEvents` concern:

```ruby
module FiresChangeEvents
  extend ActiveSupport::Concern

  included do
    after_commit :fire_change_event
  end

  def fire_change_event
    ChangedModelList.changed(self)
  end
end
```

Models could hook into it by including `FiresChangeEvents`, for example:

```ruby
class Event < ActiveRecord::Base
  include FiresChangeEvents
end
```

To capture changes resulting from controller actions, I added a `before_action` and an `after_action` to `ApplicationController`:

```ruby
class ApplicationController < ActionController::Base
  before_action :restart_changed_model_list
  after_action  :fire_changed_model_list

  def restart_changed_model_list
    ChangedModelList.restart!
  end

  def fire_changed_model_list
    ChangedModelList.fire!
  end
end
```

# Responding to Changes on the Client

Each client will receive an event & payload when records are changed. The client must inform any subscribers of the changes.

I made a `PusherStore` which actually did two things:

- As a singleton, the class subscribed to the Pusher channel and handled events.
- As a constructor, it was the superclass of Flux-ish stores which React components would subscribe to.

(If it bothers you that it does two things, let me know on our [careers page] :D)


```coffeescript
class CheckIns.Stores.PusherStore extends CheckIns.Stores.RestStore
  constructor: ->
    super
    @_subscribe()

  # Add a handler for this model using `@::modelName`
  _subscribe: ->
    throw("You must define #{@constructor.name}::modelName") unless @modelName?
    PusherStore._modelHandlers[@modelName] = (data) => @emitChange(data)
    PusherStore._ensureSubscribed()

  # This is a "global" collection of model => func pairs
  # that will be called whenever any records have changes
  @_modelHandlers: {}

  # Subscribes to the Pusher channel, but only once
  @_ensureSubscribed: ->
    return if @_listening
    @_listening = true
    throw("You must assign a pusher channel to PusherStore.channel") unless @channel?
    @channel.bind "records_changed", @_handleChangeData.bind(@)

  # Distributes Pusher payloads by looking up handlers
  # and calling them for each changed record
  @_handleChangeData: (data) ->
    for modelName, records of data.records
      if handler = @_modelHandlers[modelName]
        for id, recordJSON of records
          handler(recordJSON)
      else
        console.warn "Pusher update for #{modelName}, but no handler was found"
```

For models that need live updates, I extend `PusherStore` and define `::modelName`:

```coffee
#= require ./pusher_store
class CheckIns.Stores.EventsStore extends CheckIns.Stores.PusherStore
  modelName: "Event"
```

At run time, `PusherStore` is given a channel to subscribe to:

```coffee
# CheckIns.channel is a Pusher channel
CheckIns.Stores.PusherStore.channel = CheckIns.channel
```

and stores are initialized:

```coffee
CheckIns.Stores.Events = new CheckIns.Stores.EventsStore
```

Now, these stores will fire change events whenver data changes on the server.

# Hooking up React Components

To hook up the UI, I follow Flux's pattern. React components subscribe to store changes during setup:

```coffee
CheckIns.EventsShowAttendance = React.createComponent
  componentDidMount: ->
    CheckIns.Stores.addChangeListener(@_handleEventChanged)
  # ...
  _handleEventChanged: (eventJSON) ->
    if eventJSON.id is @props.event.id
      # Update yourself accordingly
```

And unsubscribe when they die:

```coffee
CheckIns.EventsShowAttendance = React.createComponent
  componentWillUnmount: ->
    CheckIns.Stores.removeChangeListener(@_handleEventChanged)
  # ...
```

These React components are sprinkled into Rails templates with the [`react-rails`] helper. For (imaginary) example:

```slim
.attendence
  = "#{@event.name} attendence: "
  = react_component("CheckIns.EventsShowAttendence", {event: @event.as_json})
```

# Wrapping Up

To (re-)implement live updates on PCO Check-ins, I:

- Created an app-wide change tracker, `ChangedModelList`
- Hooked the tracker up to the request/response cycle with `before_filter`/`after_filter`
- Used a Flux-ish store, `PusherStore`, get data into the UI

I'm happy with this solution because:

- There are no enormous "God-objects"
- The server-side code is easy to test
- The client-side code is predictable thanks to React instead of jQuery (no selectors, yay)
- The client-side code is visible thanks to `react_component` in the template and the obvious subscribe/unsubscribe in the component code
