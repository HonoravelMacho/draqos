import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:draqos_core/draqos_core.dart';
import 'package:http/http.dart' as http;

/// HTTP implementation of the core repository contracts.
/// Speaks docs/api.yaml against the daemon admin API (tailnet only).
/// Android and desktop are pure clients — they never serve.
class DraqosClient implements DynamicQrRepository {
  final String baseUrl;
  final String token;
  final http.Client httpClient;

  DraqosClient({
    required this.baseUrl,
    required this.token,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  factory DraqosClient.paired(
    PairingPayload pairing, {
    http.Client? httpClient,
  }) {
    return DraqosClient(
      baseUrl: pairing.baseUrl,
      token: pairing.token,
      httpClient: httpClient,
    );
  }

  Uri _u(String path) =>
      Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}$path');

  Map<String, String> get _headers => {
    'authorization': 'Bearer $token',
    'content-type': 'application/json',
  };

  Never _translate(Object e, StackTrace st) {
    if (e is SocketException ||
        e is TimeoutException ||
        e is http.ClientException) {
      throw DaemonUnreachable(
        DaemonUnreachableKind.pcOffline,
        'PC unreachable: is it online, awake and on the same tailnet? '
        '(Note: Android allows a single VPN at a time — Tailscale must be the active one.)',
      );
    }
    throw DaemonUnreachable(
      DaemonUnreachableKind.unknown,
      'Unexpected client error: $e',
    );
  }

  void _checkAuth(http.Response r) {
    if (r.statusCode == 401) {
      throw const DaemonUnreachable(
        DaemonUnreachableKind.unauthorized,
        'Rejected by the daemon: token invalid or rotated. Pair again.',
      );
    }
  }

  @override
  Future<Result<List<DynamicQr>>> list() async {
    try {
      final r = await httpClient
          .get(_u('/api/qrs'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      _checkAuth(r);
      if (r.statusCode != 200) return Err('list failed: ${r.statusCode}');
      final items = jsonDecode(r.body) as List;
      return Ok(
        items
            .map((e) => DynamicQr.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, st) {
      if (e is DaemonUnreachable) rethrow;
      _translate(e, st);
    }
  }

  @override
  Future<Result<DynamicQr>> get(String id) async {
    try {
      final r = await httpClient
          .get(_u('/api/qrs/$id'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      _checkAuth(r);
      if (r.statusCode == 404) return const Err('not found', code: 'not_found');
      if (r.statusCode != 200) return Err('get failed: ${r.statusCode}');
      return Ok(DynamicQr.fromJson(jsonDecode(r.body) as Map<String, dynamic>));
    } catch (e, st) {
      if (e is DaemonUnreachable) rethrow;
      _translate(e, st);
    }
  }

  @override
  Future<Result<DynamicQr>> create(String id, DynamicQrInput input) async {
    try {
      final r = await httpClient
          .post(
            _u('/api/qrs'),
            headers: _headers,
            body: jsonEncode({'id': id, ...input.toJson()}),
          )
          .timeout(const Duration(seconds: 10));
      _checkAuth(r);
      if (r.statusCode == 409) {
        return const Err('id already exists', code: 'conflict');
      }
      if (r.statusCode != 201) {
        final msg = _apiError(r);
        return Err(msg, code: 'validation');
      }
      return Ok(DynamicQr.fromJson(jsonDecode(r.body) as Map<String, dynamic>));
    } catch (e, st) {
      if (e is DaemonUnreachable) rethrow;
      _translate(e, st);
    }
  }

  @override
  Future<Result<DynamicQr>> update(String id, DynamicQrInput input) async {
    try {
      final r = await httpClient
          .put(
            _u('/api/qrs/$id'),
            headers: _headers,
            body: jsonEncode(input.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      _checkAuth(r);
      if (r.statusCode == 404) return const Err('not found', code: 'not_found');
      if (r.statusCode != 200) {
        return Err(_apiError(r), code: 'validation');
      }
      return Ok(DynamicQr.fromJson(jsonDecode(r.body) as Map<String, dynamic>));
    } catch (e, st) {
      if (e is DaemonUnreachable) rethrow;
      _translate(e, st);
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final r = await httpClient
          .delete(_u('/api/qrs/$id'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      _checkAuth(r);
      if (r.statusCode == 404) return const Err('not found', code: 'not_found');
      if (r.statusCode != 204) return Err('delete failed: ${r.statusCode}');
      return const Ok(null);
    } catch (e, st) {
      if (e is DaemonUnreachable) rethrow;
      _translate(e, st);
    }
  }

  Future<ScanStats> stats(String id) async {
    try {
      final r = await httpClient
          .get(_u('/api/qrs/$id/stats'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      _checkAuth(r);
      if (r.statusCode != 200) throw Err('stats failed: ${r.statusCode}');
      return ScanStats.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    } catch (e, st) {
      if (e is DaemonUnreachable) rethrow;
      _translate(e, st);
    }
  }

  Future<DaemonStatus> status() async {
    try {
      final r = await httpClient
          .get(_u('/api/status'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      _checkAuth(r);
      if (r.statusCode != 200) throw Err('status failed: ${r.statusCode}');
      return DaemonStatus.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    } catch (e, st) {
      if (e is DaemonUnreachable) rethrow;
      _translate(e, st);
    }
  }

  Future<String> rotateToken() async {
    try {
      final r = await httpClient
          .post(_u('/api/token/rotate'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      _checkAuth(r);
      if (r.statusCode != 200) throw Err('rotate failed: ${r.statusCode}');
      return (jsonDecode(r.body) as Map)['token'] as String;
    } catch (e, st) {
      if (e is DaemonUnreachable) rethrow;
      _translate(e, st);
    }
  }

  String _apiError(http.Response r) {
    try {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      return body['error'] as String? ?? 'request failed: ${r.statusCode}';
    } catch (_) {
      return 'request failed: ${r.statusCode}';
    }
  }

  void close() => httpClient.close();
}

/// Human-readable hint per failure kind (shown in the app).
String unreachableHint(DaemonUnreachable e) {
  switch (e.kind) {
    case DaemonUnreachableKind.pcOffline:
      return 'PC offline? Check: PC powered on and awake (sleep kills the '
          'daemon), Tailscale running on BOTH devices, same tailnet, and '
          'on Android Tailscale must be the active VPN (only one at a time).';
    case DaemonUnreachableKind.tailscaleOff:
      return 'Tailscale looks off. Start Tailscale on this device and on the PC.';
    case DaemonUnreachableKind.unauthorized:
      return 'The daemon rejected the token. Pair again from the PC screen.';
    case DaemonUnreachableKind.unknown:
      return e.message;
  }
}
