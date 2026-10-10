import 'dart:convert';
import 'dart:io';

import 'package:draqos_core/draqos_core.dart';
import 'package:draqos_server/draqos_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// Fake tailscale CLI for tunnel tests.
class FakeRunner implements CommandRunner {
  final List<List<String>> calls = [];
  String statusJson = jsonEncode({
    'Self': {'DNSName': 'mypc.cool-tail.ts.net.'},
  });

  @override
  Future<CommandResult> run(String exe, List<String> args) async {
    calls.add([exe, ...args]);
    if (args.contains('--json')) return CommandResult(0, statusJson, '');
    return const CommandResult(0, 'ok', '');
  }
}

Handler makeHandler(SqliteStore store, AdminAuth auth, FakeRunner runner) {
  return buildHandler(
    store: store,
    auth: auth,
    tunnels: TailscaleTunnelProvider(runner: runner),
    localPort: 8471,
  );
}

Future<AdminAuth> tempAuth() async {
  final dir = await Directory.systemTemp.createTemp('draqos-auth');
  return AdminAuth.load(dir);
}

Future<Response> call(
  Handler h,
  String method,
  String path, {
  Map<String, String>? headers,
  Object? body,
}) async {
  final req = Request(
    method,
    Uri.parse('http://x$path'),
    headers: headers,
    body: body == null ? null : jsonEncode(body),
  );
  return h(req);
}

void main() {
  group('admin CRUD', () {
    test('full lifecycle + validation + auth', () async {
      final store = SqliteStore.memory();
      final auth = await tempAuth();
      final h = makeHandler(store, auth, FakeRunner());
      final good = {'authorization': 'Bearer ${auth.token}'};

      expect((await call(h, 'GET', '/api/qrs')).statusCode, 401);

      var res = await call(
        h,
        'POST',
        '/api/qrs',
        headers: good,
        body: {
          'id': 'abc123',
          'name': 'Site',
          'description': '',
          'destinationUrl': 'https://example.com',
          'styleJson': '{}',
          'active': true,
        },
      );
      expect(res.statusCode, 201);

      // Invalid URL rejected.
      res = await call(
        h,
        'POST',
        '/api/qrs',
        headers: good,
        body: {
          'id': 'bad1',
          'name': 'x',
          'description': '',
          'destinationUrl': 'not-a-url',
          'styleJson': '{}',
        },
      );
      expect(res.statusCode, 400);

      // Duplicate id -> 409.
      res = await call(
        h,
        'POST',
        '/api/qrs',
        headers: good,
        body: {
          'id': 'abc123',
          'name': 'dup',
          'description': '',
          'destinationUrl': 'https://example.com/2',
          'styleJson': '{}',
        },
      );
      expect(res.statusCode, 409);

      res = await call(h, 'GET', '/api/qrs/abc123', headers: good);
      expect(res.statusCode, 200);

      res = await call(
        h,
        'PUT',
        '/api/qrs/abc123',
        headers: good,
        body: {
          'name': 'Site 2',
          'description': 'd',
          'destinationUrl': 'https://example.org/new',
          'styleJson': '{}',
          'active': true,
        },
      );
      expect(res.statusCode, 200);
      final updated = jsonDecode(await res.readAsString());
      expect(updated['destinationUrl'], 'https://example.org/new');

      res = await call(h, 'DELETE', '/api/qrs/abc123', headers: good);
      expect(res.statusCode, 204);
      res = await call(h, 'GET', '/api/qrs/abc123', headers: good);
      expect(res.statusCode, 404);
      store.close();
    });

    test('token rotation invalidates the old token', () async {
      final store = SqliteStore.memory();
      final auth = await tempAuth();
      final h = makeHandler(store, auth, FakeRunner());
      final old = {'authorization': 'Bearer ${auth.token}'};
      final res = await call(h, 'POST', '/api/token/rotate', headers: old);
      expect(res.statusCode, 200);
      final body = jsonDecode(await res.readAsString());
      expect((body['token'] as String).length, 64);
      expect((await call(h, 'GET', '/api/qrs', headers: old)).statusCode, 401);
      expect(
        (await call(
          h,
          'GET',
          '/api/qrs',
          headers: {'authorization': 'Bearer ${body['token']}'},
        )).statusCode,
        200,
      );
      store.close();
    });
  });

  group('public redirect + scan counter', () {
    test('302 counts scans, inactive/missing 404s, no IPs stored', () async {
      final store = SqliteStore.memory();
      final auth = await tempAuth();
      final h = makeHandler(store, auth, FakeRunner());
      final good = {'authorization': 'Bearer ${auth.token}'};
      await call(
        h,
        'POST',
        '/api/qrs',
        headers: good,
        body: {
          'id': 'pub1',
          'name': 'p',
          'description': '',
          'destinationUrl': 'https://example.com/landing',
          'styleJson': '{}',
        },
      );

      // Public route needs NO auth.
      var res = await call(h, 'GET', '/r/pub1');
      expect(res.statusCode, 302);
      expect(res.headers['location'], 'https://example.com/landing');
      await call(h, 'GET', '/r/pub1');
      await call(h, 'GET', '/r/nope', headers: good);

      res = await call(h, 'GET', '/api/qrs/pub1/stats', headers: good);
      final stats = ScanStats.fromJson(
        jsonDecode(await res.readAsString()) as Map<String, dynamic>,
      );
      expect(stats.total, 2);

      // Scans table carries no IP / personal columns.
      final cols = store.db.select('PRAGMA table_info(scans);');
      final names = cols.map((c) => c['name'] as String).toSet();
      expect(names, {'rowid', 'qr_id', 'scanned_at'});

      // Deactivate -> public 404, admin still sees it.
      await call(
        h,
        'PUT',
        '/api/qrs/pub1',
        headers: good,
        body: {
          'name': 'p',
          'description': '',
          'destinationUrl': 'https://example.com/landing',
          'styleJson': '{}',
          'active': false,
        },
      );
      expect((await call(h, 'GET', '/r/pub1')).statusCode, 404);
      store.close();
    });
  });

  group('tunnel providers', () {
    test('tailscale private uses serve --bg --https', () async {
      final runner = FakeRunner();
      final p = TailscaleTunnelProvider(runner: runner);
      final res = await p.startPrivate(8471);
      expect(res, isA<Ok<String>>());
      expect((res as Ok<String>).value, 'https://mypc.cool-tail.ts.net');
      expect(
        runner.calls.any(
          (c) =>
              c.contains('serve') &&
              c.contains('--bg') &&
              c.contains('--https=443'),
        ),
        isTrue,
      );
    });

    test(
      'tailscale public scopes funnel to /r and refuses bad ports',
      () async {
        final runner = FakeRunner();
        final p = TailscaleTunnelProvider(runner: runner, publicPort: 1234);
        final bad = await p.startPublic(8471);
        expect(bad, isA<Err<String>>());

        final okP = TailscaleTunnelProvider(runner: runner);
        final res = await okP.startPublic(8471);
        expect(res, isA<Ok<String>>());
        final funnelCall = runner.calls.firstWhere((c) => c.contains('funnel'));
        expect(funnelCall, contains('--set-path=/r'));
        expect(funnelCall.any((a) => a.startsWith('/api')), isFalse);
      },
    );

    test('offline tailscale yields clear error, not a crash', () async {
      final runner = FakeRunner()..statusJson = '{}';
      final p = TailscaleTunnelProvider(runner: runner);
      final res = await p.startPrivate(8471);
      expect(res, isA<Err<String>>());
      expect((res as Err<String>).code, 'tailscale_off');
    });

    test('cloudflare provider starts and stops', () async {
      final runner = FakeRunner();
      final p = CloudflareTunnelProvider(
        runner: runner,
        hostname: 'qr.example.com',
      );
      final res = await p.startPublic(8471);
      expect((res as Ok<String>).value, 'https://qr.example.com');
      expect(await p.stop(), isA<Ok<void>>());
    });
  });

  group('pairing payload', () {
    test('encode/decode round-trip', () {
      const p = PairingPayload(
        baseUrl: 'https://mypc.tail.ts.net:443',
        token: 'abc',
        machine: 'mypc',
      );
      final back = PairingPayload.decode(p.encode());
      expect(back.baseUrl, p.baseUrl);
      expect(back.token, 'abc');
      expect(() => PairingPayload.decode('https://x'), throwsFormatException);
    });
  });
}
