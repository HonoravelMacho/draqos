import 'dart:io';
import 'dart:math';

/// Admin bearer token: generated once (first run), persisted with
/// owner-only permissions, rotated explicitly via the API.
class AdminAuth {
  String _token;
  final File file;

  AdminAuth._(this._token, this.file);

  String get token => _token;

  static Future<AdminAuth> load(Directory dataDir) async {
    await dataDir.create(recursive: true);
    final file = File('${dataDir.path}/admin_token');
    if (await file.exists()) {
      final saved = (await file.readAsString()).trim();
      if (saved.isNotEmpty) return AdminAuth._(saved, file);
    }
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    final token = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    // Best effort: owner-only permissions (POSIX).
    try {
      await file.writeAsString('$token\n', flush: true);
      if (!Platform.isWindows) {
        await Process.run('chmod', ['600', file.path]);
      }
    } catch (_) {
      await file.writeAsString('$token\n', flush: true);
    }
    return AdminAuth._(token, file);
  }

  bool check(String? header) {
    if (header == null) return false;
    final parts = header.split(' ');
    if (parts.length != 2 || parts.first != 'Bearer') return false;
    return _constantTime(parts[1], _token);
  }

  Future<String> rotate() async {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    _token = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await file.writeAsString('$_token\n', flush: true);
    return _token;
  }

  static bool _constantTime(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
