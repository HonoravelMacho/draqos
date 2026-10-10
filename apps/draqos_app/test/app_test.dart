import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:draqos_app/main.dart';

void main() {
  testWidgets('app boots into static studio', (t) async {
    await t.pumpWidget(const ProviderScope(child: DraqosApp()));
    await t.pump();
    expect(find.text('DRAQOS · STATIC STUDIO'), findsOneWidget);
    expect(find.text('TEST READ'), findsOneWidget);
  });
}
