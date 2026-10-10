import 'package:draqos_core/draqos_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:draqos_app/main.dart';
import 'package:draqos_app/session.dart';

class FakeRepo implements DynamicQrRepository {
  final List<DynamicQr> items;
  FakeRepo(this.items);

  @override
  Future<Result<List<DynamicQr>>> list() async => Ok(items);

  @override
  Future<Result<DynamicQr>> get(String id) async =>
      Ok(items.firstWhere((e) => e.id == id));

  @override
  Future<Result<DynamicQr>> create(String id, DynamicQrInput input) async =>
      throw UnimplementedError();

  @override
  Future<Result<DynamicQr>> update(String id, DynamicQrInput input) async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> delete(String id) async {
    items.removeWhere((e) => e.id == id);
    return const Ok(null);
  }
}

DynamicQr sampleQr() => DynamicQr(
  id: 'abc123',
  name: 'Site',
  description: '',
  destinationUrl: 'https://example.com',
  styleJson: '{}',
  active: true,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

void main() {
  testWidgets('app boots into static studio', (t) async {
    await t.pumpWidget(const ProviderScope(child: DraqosApp()));
    await t.pump();
    expect(find.text('DRAQOS · STATIC STUDIO'), findsOneWidget);
    expect(find.text('TEST READ'), findsOneWidget);
  });

  testWidgets('dynamic tab asks to pair when unpaired', (t) async {
    await t.pumpWidget(const ProviderScope(child: DraqosApp()));
    await t.pump();
    await t.tap(find.text('Dynamic'));
    await t.pump();
    expect(find.text('NOT PAIRED'), findsOneWidget);
  });

  testWidgets('dynamic list renders items when paired (fake repo)', (t) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          pairingProvider.overrideWith(
            (ref) => const PairingPayload(
              baseUrl: 'https://pc.tail.ts.net',
              token: 'tok',
              machine: 'pc',
            ),
          ),
          repoProvider.overrideWith((ref) => FakeRepo([sampleQr()])),
          statsProvider.overrideWith(
            (ref, id) async => ScanStats(qrId: id, total: 7, perDay: const {}),
          ),
        ],
        child: const DraqosApp(),
      ),
    );
    await t.pump();
    await t.tap(find.text('Dynamic'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('/r/abc123'), findsOneWidget);
    expect(find.textContaining('Scans: 7'), findsOneWidget);
  });
}
