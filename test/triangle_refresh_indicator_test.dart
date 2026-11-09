import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trainvent_general/trainvent_general.dart';

void main() {
  late int refreshes;
  late Completer<void> done;

  setUp(() {
    refreshes = 0;
    done = Completer<void>();
  });

  Widget app({ScrollPhysics? physics}) => MaterialApp(
    home: Scaffold(
      body: TriangleRefreshIndicator(
        onRefresh: () {
          refreshes++;
          return done.future;
        },
        child: ListView(
          physics: physics ?? const AlwaysScrollableScrollPhysics(),
          children: [for (var i = 0; i < 3; i++) ListTile(title: Text('$i'))],
        ),
      ),
    ),
  );

  TriangleLoadingIndicator trace(WidgetTester tester) =>
      tester.widget(find.byType(TriangleLoadingIndicator));

  Future<void> pull(WidgetTester tester, double distance) async {
    final gesture = await tester.startGesture(tester.getCenter(find.text('0')));
    for (var moved = 0.0; moved < distance; moved += 10) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
  }

  Future<void> finish(WidgetTester tester) async {
    done.complete();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  for (final (name, physics) in [
    (
      'clamping',
      const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
    ),
    (
      'bouncing',
      const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
    ),
  ]) {
    testWidgets('$name: a long pull refreshes and runs the trace until done', (
      tester,
    ) async {
      await tester.pumpWidget(app(physics: physics));
      await pull(tester, 300);

      expect(refreshes, 1);
      expect(trace(tester).progress, isNull);

      await finish(tester);
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );
    });
  }

  testWidgets('a short pull winds the trace but does not refresh', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    final gesture = await tester.startGesture(tester.getCenter(find.text('0')));
    for (var i = 0; i < 3; i++) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump();
    }
    final wound = trace(tester).progress!.value;
    expect(wound, greaterThan(0));
    expect(wound, lessThan(1));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(refreshes, 0);
  });

  testWidgets('pulling while refreshing does not start another refresh', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await pull(tester, 300);
    await pull(tester, 300);
    expect(refreshes, 1);
    await finish(tester);
  });
}
