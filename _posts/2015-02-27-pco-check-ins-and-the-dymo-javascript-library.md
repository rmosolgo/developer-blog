---
layout: post
title:  "PCO Check-Ins and the DYMO Plugin"
date:   2015-02-27 08:52:13
team: web
header: /assets/images/check-ins-logo.png
author: Robert Mosolgo
---

PCO Check-Ins uses the [DYMO's browser plugin](http://developers.dymo.com/2014/03/24/javascript-library-1-2-6-now-available/) to print labels from webpages. It's been a great tool and it enabled us to serve our customers on the platform we know best, the web. We're also happy to integrate with DYMO printers because they're reliable and inexpensive.

## How We Use It

Our use of the DYMO plugin has a few parts:

- A `PrintersStore` watches for connected printers and exposes them to the rest of the application
- A `CheckInPrinter` takes data and feeds it to the DYMO plugin (so that labels are actually printed)
- A `PendingCheckInGroupsStore` listens for push notifications and watches the print queue, invoking `CheckInPrinter` with check-in data when applicable

Let's look at each of those more closely.

### PrintersStore

`PrintersStore` is a [Flux store](http://facebook.github.io/flux/docs/overview.html#stores) which polls for available printers. When inventory of available printers changes, `PrintersStore` emits a change event.

`PrintersStore` also exposes available printers via `getConnectedPrinters()`. This method wraps the DYMO API and removes printers where `isConnected=false`.

Other parts of the app which care about available printers may subcribe to `PrintersStore`'s change events. For example, a `PrinterConnectionChecker` subscribes to those change events and, if there aren't any printers connected, displays an alert.

### CheckInPrinter

`CheckInPrinter` wraps the DYMO `printLabel` API. It accepts application data for label content & quantity, then prepares it for printing and prints it with the DYMO JavaScript framework.

There's not too much to `CheckInPrinter`, except that it also handles printing to Citizen printers if the page is open in our iOS app.

### PendingCheckInGroupsStore

A `CheckInGroup` is created when one or more people checks in to an event. Since labels-to-print is calculated based on the people who checked in together, it's essentially equivalent to a print job.

After someone checks in, `PendingCheckInGroupsStore` handles some push notifications by sending a given group to the `CheckInPrinter`. It's handled via push notification becuase the labels might be set to print at a different station than where the person checked in. The notification is sent to every client in the system; each client is responsible for picking up its own notificaitons and responding to them.

However, `PendingCheckInGroupsStore` also polls the server for any outstanding print jobs. This is because a push notification might fail to come through the system. We don't want jobs to be completely lost in that case. If the `PendingCheckInGroupsStore` finds a backlog, it prompts the user to print the backlog or dismiss it.

## Things We've Learned

There are some good __resources__ available for the DYMO plugin:

- The [DYMO developer blog](http://developers.dymo.com/) has been a great resource. I've asked a few questions there and gotten responses back in a day or two.
- The [JS API documentation](http://labelwriter.com/software/dls/sdk/docs/DYMOLabelFrameworkJavaScriptHelp/symbols/dymo.label.framework.html) is bare-bones but sufficient. As far as I know, it's the only way to learn the capabilities of the JS framework.

__Interfacing with hardware is hard.__ The DYMO plugin is a black box and it's hard to know exactly what OS/hardware realities map to which plugin outputs. We implemented our own diagnostic screen, but some subtleties are still lost on us. The vast majority of printing issues are resolved with an uninstall-restart-reinstall-restart process.

__You never know where printers are going to run off to.__ Printers can disappear on you, most notably by opening other tabs that also use that printer. To mitigate this, we poll for a printer and show a warning right away if we can't find one, but we think we'll need to use one.

__The DYMO plugin _really_ doesn't like quantity=0.__ If you ask to print `0` copies of a label, it will print 1. If you ask to print a `LabelSet` with no `LabelRecord`s, it will either print 1 label (on Mac) or fail altogether (on Windows).


## Pros & Cons

After about a year with the DYMO plugin, here's how I see it:

| Pros  | Cons |
|----- | ---- |
| Your web app can print labels! | It's a closed-source plugin without a lot of documentation, which is tough if you're used to open-source development. |
| DYMO makes good, inexpensive hardware, which is good for our customers | Depends on NPAPI, which is being sunsetted by Chrome (although [DYMO is aware](http://developers.dymo.com/2014/12/04/dymo-label-framework-and-chrome/) and may be providing another solution) |
| Good support via comments on the developer blog | |

I can't really compare the stability of the browser plugin to other options. Some of our users have trouble getting their local environment to play well with the plugin and our app, but I don't know how our troubles compare to those of other printer-reliant apps!


