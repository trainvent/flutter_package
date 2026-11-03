import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:trainvent_general_example/screens/triangle_loading_indicator_screen.dart';

void main() {
  testWidgets('Fuze and Continuous are variants within the Trace category', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: TriangleLoadingIndicatorScreen()),
    );
    expect(find.text('Continuous'), findsNothing);
    await tester.tap(
      find.byType(DropdownButtonFormField<TriangleLoadingIndicatorMode>),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Trace').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Fuze'), findsOneWidget);
    expect(find.text('Continuous'), findsOneWidget);
    expect(find.text('Zoom spin'), findsNothing);
    TriangleLoadingIndicator preview() =>
        tester.widget<TriangleLoadingIndicator>(
          find.byKey(const ValueKey('triangle-playground-preview')),
        );
    expect(preview().mode, TriangleLoadingIndicatorMode.trace);
    expect(preview().traceStyle, TraceStyle.fuze);
    await tester.tap(find.text('Continuous'));
    await tester.pump();
    expect(preview().mode, TriangleLoadingIndicatorMode.trace);
    expect(preview().traceStyle, TraceStyle.continuous);
    expect(preview().showArrow, isTrue);
    await tester.tap(find.byKey(const ValueKey('continuous-arrow-switch')));
    await tester.pump();
    expect(preview().showArrow, isFalse);
    await tester.tap(find.byKey(const ValueKey('continuous-arrow-switch')));
    await tester.pump();
    expect(preview().showArrow, isTrue);
    expect(preview().iterationDuration, const Duration(milliseconds: 1800));
    final categoryFinder = find.byType(
      DropdownButtonFormField<TriangleLoadingIndicatorMode>,
    );
    var previousCategory = tester.widget(categoryFinder);
    var categoryRebuilds = 0;
    final previewPaintFinder = find.descendant(
      of: find.byKey(const ValueKey('triangle-playground-preview')),
      matching: find.byType(CustomPaint),
    );
    final initialPainter = tester
        .widget<CustomPaint>(previewPaintFinder)
        .painter;
    final stopwatch = Stopwatch()..start();
    for (var frame = 0; frame < 120; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      final category = tester.widget(categoryFinder);
      if (!identical(category, previousCategory)) categoryRebuilds++;
      previousCategory = category;
      expect(
        tester.widget<CustomPaint>(previewPaintFinder).painter,
        same(initialPainter),
        reason: 'Trace must repaint without rebuilding',
      );
    }
    stopwatch.stop();
    debugPrint(
      'Continuous: 120 frames in ${stopwatch.elapsedMilliseconds} ms; '
      '$categoryRebuilds category rebuilds',
    );
    expect(
      categoryRebuilds,
      0,
      reason: 'Animation frames must not rebuild static controls',
    );
    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Play'), findsOneWidget);
    final pausedProgress = preview().progress!.value;
    await tester.pump(const Duration(milliseconds: 200));
    expect(preview().progress!.value, pausedProgress);
    await tester.tap(find.text('Play'));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Pause'), findsOneWidget);
    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.byTooltip('Reset to defaults'));
    await tester.pump();
    expect(preview().mode, TriangleLoadingIndicatorMode.place);
    expect(find.text('Continuous'), findsNothing);
    expect(find.text('Zoom spin'), findsOneWidget);
    expect(find.byKey(const ValueKey('iteration-count-field')), findsOneWidget);
    await tester.tap(find.text('Color'));
    await tester.pump();
    expect(preview().showFill, isTrue);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('endless-iterations-button')),
          )
          .isSelected,
      isTrue,
    );
    expect(
      (preview().progress as AnimationController).duration,
      const Duration(seconds: 204),
    );
    final countField = find.byKey(const ValueKey('iteration-count-field'));
    await tester.enterText(countField, '100');
    await tester.pump();
    expect(preview().iterations, 100);
    await tester.enterText(countField, '3');
    await tester.pump();
    expect(preview().iterations, 3);
    await tester.pump(const Duration(seconds: 11));
    expect((preview().progress as AnimationController).isCompleted, isTrue);
    expect(find.text('Play'), findsOneWidget);
    await tester.tap(find.byTooltip('Endless'));
    await tester.pump();
    expect(preview().iterations, isNull);
    expect(tester.widget<TextField>(countField).controller!.text, isEmpty);
    expect((preview().progress as AnimationController).isAnimating, isTrue);
    await tester.enterText(countField, '0');
    await tester.pump();
    expect(find.text('Use 1 or more'), findsOneWidget);
    expect(preview().iterations, isNull);
    await tester.tap(find.byTooltip('Endless'));
    await tester.pump();
    expect(find.text('Use 1 or more'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
