import 'dart:convert';
import 'dart:io';

import 'package:draqos_client/draqos_client.dart';
import 'package:draqos_core/draqos_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

MockClient mock(Map<String, http.Response> routes) {
  return MockClient((req) async {
    final key = '${req.method} ${req.url.path}';
    return routes[key] ??
        http.Response(jsonEncode({'error': 'not found'}), 404);
  });
}

Map<String, dynamic> qrJson(String id) => {
  'id': id,
  'name': 'N',
  'description': '',
  'destinationUrl': 'https://example.com',
  'styleJson': '{}',
  'active': true,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
};

void main() {
  group('DraqosClient', () {
    test('list/get/create/update/delete round-trip', () async {
      final c = DraqosClient(
        baseUrl: 'https://pc.tail.ts.net',
        token: 't',
        httpClient: mock({
          'GET /api/qrs': http.Response(jsonEncode([qrJson('a')]), 200),
          'GET /api/qrs/a': http.Response(jsonEncode(qrJson('a')), 200),
          'POST /api/qrs': http.Response(jsonEncode(qrJson('b')), 201),
          'PUT /api/qrs/a': http.Response(jsonEncode(qrJson('a')), 200),
          'DELETE /api/qrs/a': http.Response('', 204),
        }),
      );
      expect(((await c.list()) as Ok<List<DynamicQr>>).value.first.id, 'a');
      expect(((await c.get('a')) as Ok<DynamicQr>).value.id, 'a');
      expect(
        ((await c.create(
                  'b',
                  const DynamicQrInput(
                    name: 'n',
                    description: '',
                    destinationUrl: 'https://example.com',
                    styleJson: '{}',
                  ),
                ))
                as Ok<DynamicQr>)
            .value
            .id,
        'b',
      );
      expect(
        ((await c.update(
                  'a',
                  const DynamicQrInput(
                    name: 'n',
                    description: '',
                    destinationUrl: 'https://example.com',
                    styleJson: '{}',
                  ),
                ))
                as Ok<DynamicQr>)
            .value
            .id,
        'a',
      );
      expect(await c.delete('a'), isA<Ok<void>>());
      c.close();
    });

    test('401 becomes unauthorized, socket becomes pcOffline', () async {
      final unauth = DraqosClient(
        baseUrl: 'https://pc.tail.ts.net',
        token: 'bad',
        httpClient: mock({}),
      );
      // default mock returns 404 for unknown routes; force 401:
      final unauth2 = DraqosClient(
        baseUrl: 'https://pc.tail.ts.net',
        token: 'bad',
        httpClient: MockClient(
          (_) async => http.Response('{"error":"x"}', 401),
        ),
      );
      await expectLater(
        unauth2.list(),
        throwsA(
          isA<DaemonUnreachable>().having(
            (e) => e.kind,
            'kind',
            DaemonUnreachableKind.unauthorized,
          ),
        ),
      );

      final offline = DraqosClient(
        baseUrl: 'https://pc.tail.ts.net',
        token: 't',
        httpClient: MockClient(
          (_) async => throw const SocketExceptionForTest(),
        ),
      );
      await expectLater(
        offline.list(),
        throwsA(
          isA<DaemonUnreachable>().having(
            (e) => e.kind,
            'kind',
            DaemonUnreachableKind.pcOffline,
          ),
        ),
      );
      unauth.close();
      unauth2.close();
      offline.close();
    });

    test('paired factory uses payload base+token', () {
      const p = PairingPayload(
        baseUrl: 'https://pc.tail.ts.net',
        token: 'tok',
        machine: 'pc',
      );
      final c = DraqosClient.paired(p);
      expect(c.baseUrl, 'https://pc.tail.ts.net');
      expect(c.token, 'tok');
      c.close();
    });
  });
}

class SocketExceptionForTest extends SocketException {
  const SocketExceptionForTest() : super('test');
}
