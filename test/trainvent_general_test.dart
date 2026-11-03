import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trainvent_general/trainvent_general.dart';

void main() {
  test('exposes the package name', () {
    expect(TrainventGeneral.packageName, 'trainvent_general');
  });

  testWidgets('exports and renders TriangleLoadingIndicator', (tester) async {
    const progress = AlwaysStoppedAnimation<double>(0.5);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TriangleLoadingIndicator(size: 64, progress: progress),
        ),
      ),
    );

    expect(find.byType(TriangleLoadingIndicator), findsOneWidget);
    expect(
      tester.getSize(find.byType(TriangleLoadingIndicator)),
      const Size.square(64),
    );
  });

  testWidgets('fuze starts with the complete circle and triangle route', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TriangleLoadingIndicator(
          size: 100,
          mode: TriangleLoadingIndicatorMode.fuze,
          iterations: 1,
          progress: AlwaysStoppedAnimation(0.0),
        ),
      ),
    );
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(TriangleLoadingIndicator),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(
      (Canvas canvas) => paint.painter!.paint(canvas, const Size.square(100)),
      paints..path(includes: [const Offset(850, 450)]),
    );
  });

  testWidgets('no-end preserves the guide and moving dash across its loop', (
    tester,
  ) async {
    const color = Colors.blue;
    expect(
      const TriangleLoadingIndicator(
        mode: TriangleLoadingIndicatorMode.fuze,
        fuzeStyle: FuzeStyle.noEnd,
      ).iterationDuration,
      const Duration(milliseconds: 1800),
    );
    for (final progress in [0.0, 0.5, 0.9, 1.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: TriangleLoadingIndicator(
            mode: TriangleLoadingIndicatorMode.fuze,
            fuzeStyle: FuzeStyle.noEnd,
            baseColor: color,
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
      void draw(Canvas canvas) =>
          paint.painter!.paint(canvas, const Size.square(100));
      expect(
        draw,
        paints
          ..path(
            color: color.withValues(alpha: 0.35),
            strokeWidth: 44,
            includes: [const Offset(850, 450)],
          )
          ..path(color: color, strokeWidth: 60),
      );
      expect(draw, isNot(paints..circle()));
      final canvas = _PathCanvas();
      draw(canvas);
      final route = canvas.paths.first.computeMetrics().single;
      final head = route.getTangentForOffset(
        ((progress + 0.26) % 1) * route.length,
      )!;
      final expectedTip = head.position + head.vector * 80;
      final arrowTip = canvas.paths.last
          .computeMetrics()
          .single
          .getTangentForOffset(0)!
          .position;
      expect((arrowTip - expectedTip).distance, lessThan(0.5));
    }
  });

  testWidgets('fuze burns away every reference segment in its recorded order', (
    tester,
  ) async {
    // Recorded from logo_animations/fuse/fuse-animation.js.
    final reference = Path()..moveTo(450, 9.45);
    for (final end in const [
      Offset(831.5275, 670.275),
      Offset(68.4725, 670.275),
      Offset(450, 9.45),
    ]) {
      reference.arcToPoint(end, radius: const Radius.circular(445));
    }
    for (final end in const [
      Offset(548.3474, 179.7927),
      Offset(831.5275, 670.275),
      Offset(634.8327, 670.275),
      Offset(68.4725, 670.275),
      Offset(166.8199, 499.9323),
      Offset(514.1917, 626.3653),
      Offset(634.8327, 670.275),
      Offset(570.641, 306.2257),
      Offset(548.3474, 179.7927),
      Offset(265.1673, 417.409),
      Offset(343.9101, 388.749),
      Offset(570.641, 306.2257),
      Offset(556.0899, 388.749),
      Offset(514.1917, 626.3653),
      Offset(450, 572.502),
      Offset(556.0899, 388.749),
      Offset(343.9101, 388.749),
      Offset(450, 572.502),
      Offset(265.1673, 417.409),
      Offset(166.8199, 499.9323),
      Offset(450, 9.45),
    ]) {
      reference.lineTo(end.dx, end.dy);
    }
    final expected = reference.computeMetrics().single;
    for (final progress in [0.0, 0.15, 0.4, 0.55, 0.8, 0.99, 1.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: TriangleLoadingIndicator(
            mode: TriangleLoadingIndicatorMode.fuze,
            iterations: 1,
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
      final canvas = _PathCanvas();
      paint.painter!.paint(canvas, const Size.square(900));
      final metrics = canvas.paths.single.computeMetrics().toList();
      if (progress == 1) {
        expect(metrics, isEmpty);
        continue;
      }
      final actual = metrics.single;
      expect(actual.length, closeTo(expected.length * (1 - progress), 0.5));
      for (var distance = 0.0; distance < actual.length; distance += 25) {
        final actualPoint = actual.getTangentForOffset(distance)!.position;
        final expectedPoint = expected
            .getTangentForOffset(expected.length * progress + distance)!
            .position;
        expect(
          (actualPoint - expectedPoint).distance,
          lessThan(0.5),
          reason: 'Reference route at progress $progress, distance $distance',
        );
      }
    }
  });
}

class _PathCanvas implements Canvas {
  final paths = <Path>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #drawPath) {
      final path = invocation.positionalArguments.first;
      if (path is Path) paths.add(Path.from(path));
    }
    return null;
  }
}
