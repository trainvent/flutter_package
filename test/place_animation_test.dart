import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainvent_general/trainvent_general.dart';

void main() {
  testWidgets('place reuses cached paths throughout the loop', (tester) async {
    for (final progress in [0.01, 0.95]) {
      await tester.pumpWidget(
        MaterialApp(
          home: TriangleLoadingIndicator(
            showFill: true,
            progress: AlwaysStoppedAnimation(progress),
          ),
        ),
      );
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(TriangleLoadingIndicator),
          matching: find.byType(CustomPaint),
        ),
      );
      final initial = _RecordingCanvas();
      paint.painter!.paint(initial, const Size.square(400));
      final stopwatch = Stopwatch()..start();
      for (var frame = 0; frame < 120; frame++) {
        paint.painter!.paint(_RecordingCanvas(), const Size.square(400));
      }
      stopwatch.stop();
      final repeated = _RecordingCanvas();
      paint.painter!.paint(repeated, const Size.square(400));
      expect(repeated.paths, isNotEmpty);
      expect(repeated.paths.length, initial.paths.length);
      for (var index = 0; index < initial.paths.length; index++) {
        expect(repeated.paths[index], same(initial.paths[index]));
      }

      debugPrint(
        'Place progress $progress: 120 paints in ${stopwatch.elapsedMicroseconds} us',
      );
    }
  });

  testWidgets(
    'forward color progression joins seamlessly at its full loop boundary',
    (tester) async {
      Future<List<int>> render(
        double progress, {
        bool oneByOne = false,
        bool zoomSpin = false,
        bool removingOld = true,
        int keepHistoryCycles = 2,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TriangleLoadingIndicator(
              showFill: true,
              hueStep: 7.123,
              oneByOne: oneByOne,
              zoomSpin: zoomSpin,
              removingOld: removingOld,
              keepHistoryCycles: keepHistoryCycles,
              progress: AlwaysStoppedAnimation(progress),
            ),
          ),
        );
        final paint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(TriangleLoadingIndicator),
            matching: find.byType(CustomPaint),
          ),
        );
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawColor(Colors.white, BlendMode.src);
        paint.painter!.paint(canvas, const Size.square(160));
        final picture = recorder.endRecording();
        final pixels = await tester.runAsync(() async {
          final image = await picture.toImage(160, 160);
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final bytes = data!.buffer.asUint8List().toList();
          image.dispose();
          return bytes;
        });
        picture.dispose();
        return pixels!;
      }

      for (final oneByOne in [false, true]) {
        for (final zoomSpin in [false, true]) {
          for (final removingOld in [false, true]) {
            for (final keepHistoryCycles in [0, 2]) {
              final first = await render(
                0,
                oneByOne: oneByOne,
                zoomSpin: zoomSpin,
                removingOld: removingOld,
                keepHistoryCycles: keepHistoryCycles,
              );
              final loop = TriangleLoadingIndicator(
                showFill: true,
                hueStep: 7.123,
                oneByOne: oneByOne,
                zoomSpin: zoomSpin,
                removingOld: removingOld,
              ).loopIterations;
              final last = await render(
                1 - 1e-7 / loop,
                oneByOne: oneByOne,
                zoomSpin: zoomSpin,
                removingOld: removingOld,
                keepHistoryCycles: keepHistoryCycles,
              );
              var difference = 0;
              for (var index = 0; index < first.length; index++) {
                difference += (first[index] - last[index]).abs();
              }
              expect(
                difference / first.length,
                lessThan(0.25),
                reason:
                    'Color loop seam: oneByOne=$oneByOne, zoomSpin=$zoomSpin, '
                    'removingOld=$removingOld, history=$keepHistoryCycles',
              );
            }
          }
        }
      }
    },
  );

  testWidgets('place animation repaints without rebuilding widgets', (
    tester,
  ) async {
    final animation = AnimationController(vsync: tester);
    addTearDown(animation.dispose);
    await tester.pumpWidget(
      MaterialApp(home: TriangleLoadingIndicator(progress: animation)),
    );
    final finder = find.descendant(
      of: find.byType(TriangleLoadingIndicator),
      matching: find.byType(CustomPaint),
    );
    final initial = tester.widget<CustomPaint>(finder);
    animation.value = 0.7;
    await tester.pump();
    expect(tester.widget<CustomPaint>(finder), same(initial));
  });

  testWidgets(
    'triangle colors advance with depth without reversing during zoom',
    (tester) async {
      const seed = Color(0xFFFF0000);
      for (final cycle in [0, 1, 2, 59]) {
        await tester.pumpWidget(
          MaterialApp(
            home: TriangleLoadingIndicator(
              showFill: true,
              baseColor: seed,
              iterations: 60,
              progress: AlwaysStoppedAnimation((cycle + 0.9) / 60),
            ),
          ),
        );
        final paint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(TriangleLoadingIndicator),
            matching: find.byType(CustomPaint),
          ),
        );
        final canvas = _RecordingCanvas();
        paint.painter!.paint(canvas, const Size.square(160));
        final expected = HSLColor.fromAHSL(
          1,
          ((cycle + 1) * 6 * 7) % 360,
          0.73,
          0.52,
        ).toColor();
        expect(canvas.fillColors.map((color) => color.toARGB32()), [
          expected.toARGB32(),
        ]);
      }
    },
  );

  test('loop period follows the geometry and forward hue steps', () {
    expect(const TriangleLoadingIndicator().loopIterations, 2);
    expect(const TriangleLoadingIndicator(showFill: true).loopIterations, 60);
    expect(
      const TriangleLoadingIndicator(
        showFill: true,
        hueStep: 10,
      ).loopIterations,
      6,
    );
    expect(
      const TriangleLoadingIndicator(
        showFill: true,
        hueStep: 7.5,
      ).loopIterations,
      8,
    );
    expect(
      const TriangleLoadingIndicator(
        showFill: true,
        hueStep: 7.123,
      ).loopIterations,
      60000,
    );
    expect(
      const TriangleLoadingIndicator(
        showFill: true,
        oneByOne: true,
      ).loopIterations,
      360,
    );
    expect(
      const TriangleLoadingIndicator(
        showFill: true,
        zoomSpin: true,
      ).loopIterations,
      60,
    );
    expect(const TriangleLoadingIndicator(zoomSpin: true).loopIterations, 1);
  });
}

class _RecordingCanvas implements Canvas {
  final paths = <Path>[];
  final fillColors = <Color>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #drawPath) {
      final path = invocation.positionalArguments.first;
      if (path is Path) paths.add(path);
      final paint = invocation.positionalArguments[1];
      if (paint is Paint && paint.style == PaintingStyle.fill) {
        fillColors.add(paint.color);
      }
    }
    return null;
  }
}
