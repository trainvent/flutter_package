# trainvent_general

Shared general-purpose utilities and widgets for Trainvent Flutter projects.
The package is intentionally small at first and provides a common home for code
that is reused by more than one application.

## Project structure

- `lib/trainvent_general.dart` is the public entry point.
- `lib/src/` contains implementation files.
- `test/` contains package tests.

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

void main() {
  print(TrainventGeneral.packageName);
}
```

## Development

Run checks from this directory:

```sh
flutter analyze
flutter test
```

Public APIs should be documented and exported from
`lib/trainvent_general.dart`. Record user-visible changes in `CHANGELOG.md`.
