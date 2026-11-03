# trainvent_general

Shared general-purpose utilities and widgets for Trainvent Flutter projects.
The package is intentionally small at first and provides a common home for code
that is reused by more than one application.

## Project structure

- `lib/trainvent_general.dart` is the public entry point.
- `lib/src/` contains implementation files.
- `test/` contains package tests.
- `example/` contains the runnable widget gallery.

## Getting started

For a package stored next to your app, add a path dependency to the app's
`pubspec.yaml`:

```yaml
dependencies:
  trainvent_general:
    path: ../trainvent_general
```

Then fetch dependencies:

```sh
flutter pub get
```

## Usage

```dart
import 'package:trainvent_general/trainvent_general.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: TriangleLoadingIndicator(size: 64),
    );
  }
}
```

`TriangleLoadingIndicator` animates continuously by default. Its color follows
the current theme's primary color; use `baseColor` to override it. You can also
provide an `Animation<double>` through `progress` when another controller should
drive the indicator.

Standard uses the original forward hue progression. With fills enabled, the
7° step per triangle repeats after 60 iterations (204 seconds, seven hue turns).
Outline-only mode repeats after two iterations. Triangle paths remain cached,
and animation frames repaint without rebuilding widgets. The loop length is
calculated from the geometry and hue step; for example, 7.5° needs eight iterations.

The indicator has two animation categories: `TriangleLoadingIndicatorMode.standard`
and `TriangleLoadingIndicatorMode.fuze`. Fuze shares one circle-and-triangle route
with two playback styles:

```dart
const TriangleLoadingIndicator(
  mode: TriangleLoadingIndicatorMode.fuze,
  fuzeStyle: FuzeStyle.trace, // Or FuzeStyle.noEnd.
)
```

`trace` starts with the complete outline and burns it away behind a glowing ember. `noEnd` loops a moving arrow over a
faint guide, using `baseColor` or the theme primary color and a default 1.8-second
iteration. Select the category and Fuze style separately in the example app.

## Development

Run the example app:

```sh
cd example
flutter pub get
flutter run
```

The example references this package through a local path dependency. Edit widgets
in `lib/src/` and hot reload the example to preview changes.

Run checks from the package directory:

```sh
flutter analyze
flutter test
```

Public APIs should be documented and exported from
`lib/trainvent_general.dart`. Record user-visible changes in `CHANGELOG.md`.
