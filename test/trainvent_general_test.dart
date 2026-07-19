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
}
