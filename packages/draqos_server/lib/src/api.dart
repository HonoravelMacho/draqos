import 'dart:convert';
import 'dart:math';

import 'package:draqos_core/draqos_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth.dart';
import 'store.dart';
import 'tunnels.dart';

const String daemonVersion = '0.1.0';

/// Builds the full daemon handler from docs/api.yaml.
/// Only /r/<id> is public; everything under /api/* needs the bearer.
Handler buildHandler({
  required SqliteStore store,
  required AdminAuth auth,
  required TailscaleTunnelProvider tunnels,
  required int localPort,
}) {
  final router = Router();

  String newId() {
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    final rng = Random.secure();
    return List.generate(
      8,
      (_) => alphabet[rng.nextInt(alphabet.length)],
    ).join();
  }

  Response json(Object body, {int status = 200}) => Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );

  // ---- public: redirect + scan counter (timestamps only) ----
  router.get('/r/<id>', (Request req, String id) async {
    final res = await store.get(id);
    if (res is Err<DynamicQr>) {
      return Response.notFound('unknown or inactive QR id');
    }
    final qr = (res as Ok<DynamicQr>).value;
    if (!qr.active) return Response.notFound('unknown or inactive QR id');
    await store.recordScan(id, DateTime.now().toUtc());
    return Response.found(qr.destinationUrl);
  });

  // ---- admin guard ----
  Response? guard(Request req) {
    if (!auth.check(req.headers['authorization'])) {
      return Response(
        401,
        body: jsonEncode({'error': 'unauthorized'}),
        headers: {'content-type': 'application/json'},
      );
    }
    return null;
  }

  // ---- admin: status ----
  router.get('/api/status', (Request req) async {
    final denied = guard(req);
    if (denied != null) return denied;
    final info = await tunnels.info();
    final st = await tunnels.status();
    return json({
      'hostname': info.dnsName.split('.').firstOrNull ?? '',
      'tailnet': info.tailnet,
      'funnelEnabled': st == TunnelStatus.running,
      'serveEnabled': st == TunnelStatus.running,
      'version': daemonVersion,
      'publicBaseUrl': info.online ? 'https://${info.dnsName}' : null,
    });
  });

  // ---- admin: CRUD ----
  router.get('/api/qrs', (Request req) async {
    final denied = guard(req);
    if (denied != null) return denied;
    final res = await store.list();
    return json(
      (res as Ok<List<DynamicQr>>).value.map((q) => q.toJson()).toList(),
    );
  });

  router.post('/api/qrs', (Request req) async {
    final denied = guard(req);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final rawId = body['id'] as String?;
    final id = (rawId == null || rawId.isEmpty) ? newId() : rawId;
    final input = DynamicQrInput.fromJson(body);
    final res = await store.create(id, input);
    if (res is Err<DynamicQr>) {
      final status = res.code == 'conflict' ? 409 : 400;
      return json({'error': res.message}, status: status);
    }
    return json((res as Ok<DynamicQr>).value.toJson(), status: 201);
  });

  router.get('/api/qrs/<id>', (Request req, String id) async {
    final denied = guard(req);
    if (denied != null) return denied;
    final res = await store.get(id);
    if (res is Err<DynamicQr>)
      return Response.notFound(jsonEncode({'error': 'not found'}));
    return json((res as Ok<DynamicQr>).value.toJson());
  });

  router.put('/api/qrs/<id>', (Request req, String id) async {
    final denied = guard(req);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final res = await store.update(id, DynamicQrInput.fromJson(body));
    if (res is Err<DynamicQr>) {
      final status = res.code == 'not_found' ? 404 : 400;
      return json({'error': res.message}, status: status);
    }
    return json((res as Ok<DynamicQr>).value.toJson());
  });

  router.delete('/api/qrs/<id>', (Request req, String id) async {
    final denied = guard(req);
    if (denied != null) return denied;
    final res = await store.delete(id);
    if (res is Err<void>)
      return Response.notFound(jsonEncode({'error': 'not found'}));
    return Response(204);
  });

  router.get('/api/qrs/<id>/stats', (Request req, String id) async {
    final denied = guard(req);
    if (denied != null) return denied;
    final existing = await store.get(id);
    if (existing is Err<DynamicQr>) {
      return Response.notFound(jsonEncode({'error': 'not found'}));
    }
    return json((await store.stats(id)).toJson());
  });

  router.post('/api/token/rotate', (Request req) async {
    final denied = guard(req);
    if (denied != null) return denied;
    return json({'token': await auth.rotate()});
  });

  return router.call;
}
