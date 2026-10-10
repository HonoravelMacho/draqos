import 'dart:io';

import 'package:draqos_client/draqos_client.dart';
import 'package:draqos_core/draqos_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pairing_store.dart';

/// Active pairing (null = not paired yet).
final pairingProvider = StateProvider<PairingPayload?>((ref) => null);

/// Repository to the daemon; null until paired.
/// In production this is always a [DraqosClient]; tests override it.
final repoProvider = Provider<DynamicQrRepository?>((ref) {
  final pairing = ref.watch(pairingProvider);
  if (pairing == null) return null;
  return DraqosClient.paired(pairing);
});

/// Scan stats loader (overridable in tests).
final statsProvider = FutureProvider.family<ScanStats, String>((ref, id) async {
  final repo = ref.watch(repoProvider);
  if (repo is DraqosClient) return repo.stats(id);
  throw const DaemonUnreachable(DaemonUnreachableKind.unknown, 'not connected');
});

final pairingStoreProvider = Provider((ref) => PairingStore());

/// True on Android: editor-only, never runs the daemon.
final isAndroidProvider = Provider((ref) => Platform.isAndroid);
