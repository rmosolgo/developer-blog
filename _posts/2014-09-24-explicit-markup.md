---
layout: post
title: In Favor of Explicit Markup
author: "Dan Ott"
team: web
---

Somewhere in the history of our young profession, `<a onclick="doSomething(true);" />` was labeled as _bad practice_. I've started to question that assumption.

Consider the _best practice_ alternative:

```html
<!-- Some HTML file -->
<a class="js-hook-that-does-something" />
```

```js
// Some JavaScript file
jQuery(function(){
  $('.js-hook-that-does-something').on('click', function(event){
    doSomething(true);
  });
});
```

This ceremony erases the clarity of the intent of this code for my teammates (including my future-self returning to this code). Also, this trivial example doesn't begin to address functionality we may want soon, such as passing arguments into `doSomething`.

The mantra of behavior in markup as _bad practice_ emerged from the evangelism of [unobtrusive javascript][] and [progressive enhancement][]. While I agree with the end-goals of these strategies, tossing out the explicitness of declaring the unobtrusive-behavior in markup seems like an unnecessary and obfuscating side-effect.

Another objection is "you're polluting the global scope with all those functions!" Fair enough, that is a valid concern.

[Batman.js][] has found a happy middle ground with their [event bindings][]. It retains the explicitness of events being declared in the markup, with the isolation of concerns via creating subclasses of `Batman.View`. I don't want the overhead of an entire Batman app, but I want its explicit markup, so I created [SimpleBehaviors][].

The goal of SimpleBehaviors is to have the explicitness of markup for clarity when returning to code, with the cleanliness of global scope to be a responsible JavaScript citizen.

How does markup look with SimpleBehaviors?

```html
<div data-behaviors="BluthActions">
  <ul>
    <li><a data-event-click="checkBananaStandForMoney">Check Banana Stand</a></li>
    <li><a data-event-click="driveStairCar">Drive the stair car</a></li>
  </ul>
</div>
```

```coffee
# bluth_actions.coffee
BluthActions =
  checkBananaStandForMoney: (event) ->
    alert("There's always money here!")
  driveStairCar: (event) ->
    alert("Vroom!");
```

No functions leaked to the global scope, and clear intent when looking at the markup. You can even nest/override behaviors!

```html
<div data-behaviors="BluthActions">
  <div data-behaviors="BusterActions">
    <ul>
      <li><a data-event-click="checkBananaStandForMoney">Check Banana Stand</a></li>
      <li><a data-event-click="driveStairCar">Drive the stair car</a></li>
    </ul>
  </div>
</div>
```

```coffee
# buster_actions.coffee
BusterActions = {
  driveStairCar: (event) ->
    alert("Buster is driving the stair car, mother!");
```

The function to execute will be looked for on `BusterActions` first, then bubble up to `BluthActions` if it's not found. Try it out:

<div data-behaviors="BluthActions">
  <ul>
    <li><strong>Bluth Actions</strong></li>
    <li><a data-event-click="checkBananaStandForMoney">Check Banana Stand</a></li>
    <li><a data-event-click="driveStairCar">Drive the stair car</a></li>
  </ul>

  <div data-behaviors="BusterActions">
    <ul>
      <li><strong>Buster Actions nested in Bluth Actions</strong></li>
      <li><a data-event-click="checkBananaStandForMoney">Check Banana Stand</a></li>
      <li><a data-event-click="driveStairCar">Drive the stair car</a></li>
    </ul>
  </div>
</div>


There's still a few things I'd like to add to SimpleBehaviors.

- Using `event.stopPropogation()` to control whether the event continues up the behaviors hierarchy. Presently, it simply stops after the first function is executed.
- Passing arguments. So far I haven't needed them in [Resources][], but there are potential use cases where they'd be necessary.
- Isolating scope even further, i.e. passing something like `<div data-behaviors="Resources.somethingParticular" />`

If you think this approach is useful, give it a shot and [let me know][] your experience. The only dependency is jQuery (I'm using 1.11).

Thanks for stopping by.

<script src="https://code.jquery.com/jquery-1.11.1.min.js"></script>
<script src="/assets/javascripts/posts/dan-ott/simple_behaviors_post.js"></script>

[unobtrusive javascript]: http://blog.teamtreehouse.com/unobtrusive-javascript-important
[progressive enhancement]: http://alistapart.com/article/understandingprogressiveenhancement
[Batman.js]: http://batmanjs.org/
[event bindings]: http://batmanjs.org/docs/api/batman.view_bindings.html#data-event
[SimpleBehaviors]: /assets/javascripts/posts/dan-ott/simple_behaviors.coffee
[Resources]: http://get.planningcenteronline.com/resources
[let me know]: http://twitter.com/home?status=@danott%20SimpleBehaviors%20is%20...
