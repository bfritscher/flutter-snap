import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap/loading.dart';

void main() {
  testWidgets('LoadingAnimation renders and animates all nine tiles', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.square(dimension: 300, child: LoadingAnimation()),
        ),
      ),
    );

    expect(find.byType(SquareTile), findsNWidgets(9));

    final firstAnimatedSquare = find.descendant(
      of: find.byType(SquareTile).first,
      matching: find.byType(Container),
    );
    final initialWidth = tester
        .widget<Container>(firstAnimatedSquare)
        .constraints!
        .maxWidth;

    await tester.pump(const Duration(milliseconds: 100));

    final animatedWidth = tester
        .widget<Container>(firstAnimatedSquare)
        .constraints!
        .maxWidth;
    expect(animatedWidth, lessThan(initialWidth));
  });
}
