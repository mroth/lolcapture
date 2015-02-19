lolcapture
==========

An experimental OSX webcam capture tool for lolcommits that includes the image resizing and text composition steps with native frameworks, removing the need for an external dependency on ImageMagick.

This is more of a testbed for ideas that may perhaps eventually make it into [VideoSnap][vs], and is not really intended for actual usage.  It's also an excuse for me to experiment with learning Swift.

[vs]: https://github.com/matthutchinson/videosnap

## Differences and gotchas
- We do a better job than the current ImageMagick solution of determining where to wrap text in edge cases (see output comparison).
- Written in Swift.  Tn retrospect, probably not a great idea, because of the following:
  - Swift bundles the entire runtime instead of relying on it being present in the OS, resulting in a ~4MB binary.  This isn't that huge but certainly is not suitable for vendoring inside a gem!
  - It's currently very difficult to use external frameworks in a Swift command line binary, see [this blog post for more information](http://colemancda.github.io/programming/2015/02/12/embedded-swift-frameworks-osx-command-line-tools/).
- Uses new `AVFoundation` framework for image capture. Likely more future proof and seems to solve the blank image warmup problem automatically for me (on my hardware at least).

## TODO

- Handle device selection instead of just using primary device.
- Figure out lineheight/spacing issue.
- Preserve JPEG EXIF metadata.
- Write git metadata to EXIF too!

## WONTFIX

- Animated GIF Capture (better just to backport promising changes from here upstream into videosnap)

## Output comparison

lolcapture:
![lolcapture](http://f.cl.ly/items/3F0N2H362k453S1f3v3i/test-capture.jpg)

lolcommits gem (using wacaw+imagemagick):
![lolcommits](http://f.cl.ly/items/00013m2s193Q0b3D211D/test-8390631112.jpg)
