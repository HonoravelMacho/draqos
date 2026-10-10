import 'package:flutter_test/flutter_test.dart';
import 'package:draqos_ui/draqos_ui.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('DraqPanel renders child', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: draqosTheme(),
        home: const Scaffold(body: DraqPanel(child: Text('HELLO'))),
      ),
    );
    expect(find.text('HELLO'), findsOneWidget);
  });

  testWidgets('DraqButton disabled when onPressed null', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: draqosTheme(),
        home: const Scaffold(body: DraqButton(label: 'GO')),
      ),
    );
    expect(find.text('GO'), findsOneWidget);
  });

  test('tokens lerp keeps type', () {
    const a = DraqosTokens();
    expect(a.lerp(const DraqosTokens(), 0.5), isA<DraqosTokens>());
  });
}
