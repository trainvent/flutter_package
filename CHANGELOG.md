## Unreleased

* Add an editable iteration count and Endless control to the example; finite counts stop after playback.

* Preserve Standard’s forward hue progression and calculate its exact loop period (60 colored iterations by default).
* Cache a bounded set of triangle paths and replace per-frame linear solves with direct transforms.
* Animate Standard through repaint notifications instead of widget rebuilds.

* Avoid per-frame page rebuilds; isolate preview/playback repaints and animate Fuze directly in its painter.

* Add a forward-facing arrowhead to the No-end animation.

* Make Fuze Trace burn away the outline instead of drawing it.

* Group Trace and No-end under the Fuze mode with a shared painter and route.
* Replace the `fuze` and `noEnd` flags with `mode` and `fuzeStyle`.

* Add `noEnd` with a moving dash along the same circle and triangle route as Fuze.

* Add `fuze` continuous circle-and-triangles tracing with a glowing ember and an example toggle.

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
