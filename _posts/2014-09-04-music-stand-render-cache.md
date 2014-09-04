---
layout: post
title:  "Music Stand Render Cache"
date:   2014-09-04 14:00:56
author:	Skylar Schipper
header: /assets/images/music-stand-icon-ios.png
team:	mobile
---

One of the challenges of [Music Stand][1] is rendering PDFs and user annotations in a timely fashion.  Each of those tasks alone isn't a big deal, but all together it's quite a challenge.  Let's take a look at how Music Stand renders and caches PDF pages.

At a super high level here's what happens when a user first loads a plan.

1.  We fetch all PDF's for the plan.  These are straightforward [NSURLSessionDownloadTasks][2].
2.  While those PDF's are downloading we get the user's annotation data from Planning Center.
3.  We render the first 3 pages for each PDF while the user is looking at the plan view.  If they select a PDF, all render jobs are immediately canceled and the PDF is displayed.
4.  The PDF view is presented with the first page of the selected PDF showing.  If the full size image is cached it's displayed, if not we render the page live to the screen.
5.  After each page is displayed the next 2 pages are loaded into memory ready to display.

Each job is performed on a concurrent queue, allowing the system to take full advantage of all the CPU/GPU resources available.  Three versions of each page are generated.  A thumbnail, full resolution with annotations and full resolution with no annotations.  Each image generated has a priority.  The first page of the first PDF in the plan has a higher priority than the last PDF's first page.  And the full resolution takes priority over the thumbnail.

Pre-rendering pages allows the app to have static image ready when the user wants to view a page.  Displaying a static image is much faster then drawing it to the screen.  We can fall back and present a page live if the pre-render fails or isn't done in time.

[Apple's Core Graphics PDF API][3] handles drawing the actual PDF.  A bitmap backed graphics context is created and the PDF is drawn into it.  Annotations are drawn in the order they were created by the user.  The [CGPath API][4] handles all annotation drawing.  The bitmap is then saved to disk as a png.  The only difference for doing this live is the drawing occurs into the UIView's backing context.

The on disk cache persists through app launches, but can be reclaimed by the system if resources become constrained.  This is great for a user if they have used the app to practice during the week.  Come Sunday morning all the pages are rendered and Music Stand's performance will be outstanding.


[1]: http://appstore.com/planningcentermusicstand
[2]: https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSessionDownloadTask_class/Reference/Reference.html
[3]: https://developer.apple.com/library/ios/documentation/graphicsimaging/Reference/CGContext/Reference/reference.html#//apple_ref/c/func/CGContextDrawPDFPage
[4]: https://developer.apple.com/library/ios/documentation/graphicsimaging/reference/CGPath/Reference/reference.html