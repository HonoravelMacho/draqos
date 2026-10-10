import 'entities.dart';
import 'result.dart';

/// Contract for dynamic-QR persistence. Implemented by the server
/// (SQLite) and consumed over HTTP by draqos_client.
abstract class DynamicQrRepository {
  Future<Result<List<DynamicQr>>> list();
  Future<Result<DynamicQr>> get(String id);
  Future<Result<DynamicQr>> create(String id, DynamicQrInput input);
  Future<Result<DynamicQr>> update(String id, DynamicQrInput input);
  Future<Result<void>> delete(String id);
}

/// Contract for scan counters (no IPs / personal data stored).
abstract class ScanRepository {
  Future<void> recordScan(String qrId, DateTime at);
  Future<ScanStats> stats(String qrId);
}
