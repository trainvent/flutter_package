# trainvent_general example

A runnable widget gallery with interactive controls for the package components.

From this directory:

```sh
flutter pub get
flutter run
```

Select TriangleLoadingIndicator in the gallery to adjust its animation and playback.
Edit shared widgets in `../lib/src/`; the app uses the local package directly and
supports hot reload.

Enter any positive iteration count to play that many iterations, or select
Endless (∞) to keep playing. Colors are calculated for each frame using the
cached geometry; the seamless color period is not a maximum iteration count.
