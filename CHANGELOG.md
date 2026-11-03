## 0.0.6

* Rename the animation types to Place (the default) and Trace.
* Rename Trace's styles to Fuze and Continuous, exposed through `traceStyle` and `TraceStyle`.
* Add `showArrow` to toggle the Continuous arrowhead, with an Arrow switch in the example.
* Update the API documentation and regression tests for the renamed types and optional arrow.

## 0.0.5

* Add the Fuze animation category with Trace (burn-away) and No-end (looping arrow) styles sharing the same circle-and-triangle route.
* Add a runnable example gallery with editable iteration counts, finite playback, and an Endless option.
* Optimize Standard with cached triangle paths, direct geometry transforms, and paint-only animation updates.
* Preserve forward hue progression and calculate seamless color loop periods from the geometry and hue step (60 colored iterations by default).
* Improve example performance by isolating animation repaints and avoiding per-frame page rebuilds.

## 0.0.1

* Create the initial reusable Flutter package structure.
* Add a documented public entry point and package identifier.
* Add and publicly export `TriangleLoadingIndicator`.

## 0.0.2

* added one by one iteration as the new default

## 0.0.3

* fixed broken endless animation
* changed the default values to most pleasing and minimalistic

## 0.0.4

* added `iterationDuration`
