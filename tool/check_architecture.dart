/// Architecture guard: fails if layering rules are violated.
///
/// Rules:
/// - draqos_core must NOT import Flutter (dart:ui / package:flutter).
/// - draqos_ui / draqos_render must NOT import draqos_client,
///   draqos_server, package:http, dart:io sockets, shelf.
/// - apps/draqos_app must NOT contain business logic imports outside
///   composition (checked loosely: no direct sqlite/shelf imports).
///
/// Run: `dart tool/check_architecture.dart` (exit code 1 on violation).
import 'dart:io';

final Map<String, List<RegExp>> _forbidden = {
  'packages/draqos_core': [
    RegExp(r'''package:flutter/'''),
    RegExp(r'''dart:ui'''),
  ],
  'packages/draqos_ui': [
    RegExp(r'''draqos_client'''),
    RegExp(r'''draqos_server'''),
    RegExp(r'''package:http/'''),
    RegExp(r'''package:shelf'''),
    RegExp(r'''package:sqlite3'''),
  ],
  'packages/draqos_render': [
    RegExp(r'''draqos_client'''),
    RegExp(r'''draqos_server'''),
    RegExp(r'''package:http/'''),
    RegExp(r'''package:shelf'''),
    RegExp(r'''package:sqlite3'''),
  ],
  'apps/draqos_app': [
    RegExp(r'''package:shelf'''),
    RegExp(r'''package:sqlite3'''),
  ],
};

Future<void> main() async {
  var failures = 0;
  for (final entry in _forbidden.entries) {
    final dir = Directory(entry.key);
    if (!await dir.exists()) continue;
    await for (final f in dir.list(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final content = await f.readAsString();
      for (final pattern in entry.value) {
        if (pattern.hasMatch(content)) {
          stderr.writeln(
            'ARCH VIOLATION: ${f.path} matches forbidden pattern "${pattern.pattern}"',
          );
          failures++;
        }
      }
    }
  }
  if (failures > 0) {
    stderr.writeln('$failures architecture violation(s).');
    exit(1);
  }
  stdout.writeln('Architecture check passed.');
}
