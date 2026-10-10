import 'dart:convert';
import 'dart:io';

import 'package:draqos_core/draqos_core.dart';
import 'package:path_provider/path_provider.dart';

/// Persists the pairing (daemon base URL + token) on device.
/// The token file is just the pairing JSON; OS app storage is
/// private to the app.
class PairingStore {
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/draqos_pairing.json');
  }

  Future<void> save(PairingPayload pairing) async {
    final f = await _file();
    await f.writeAsString(
      jsonEncode({
        'baseUrl': pairing.baseUrl,
        'token': pairing.token,
        'machine': pairing.machine,
      }),
    );
  }

  Future<PairingPayload?> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return PairingPayload(
        baseUrl: json['baseUrl'] as String,
        token: json['token'] as String,
        machine: json['machine'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final f = await _file();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
