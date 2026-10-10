import 'package:draqos_core/draqos_core.dart';
import 'package:sqlite3/sqlite3.dart';

/// SQLite implementation of the core repository contracts.
/// Scan table stores timestamps only — never IPs or personal data.
class SqliteStore implements DynamicQrRepository, ScanRepository {
  final Database db;

  SqliteStore(this.db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS qrs(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        destination_url TEXT NOT NULL,
        style_json TEXT NOT NULL DEFAULT '{}',
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS scans(
        rowid INTEGER PRIMARY KEY AUTOINCREMENT,
        qr_id TEXT NOT NULL,
        scanned_at TEXT NOT NULL
      );
    ''');
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_scans_qr ON scans(qr_id, scanned_at);',
    );
  }

  factory SqliteStore.open(String path) => SqliteStore(sqlite3.open(path));
  factory SqliteStore.memory() => SqliteStore(sqlite3.openInMemory());

  DynamicQr _row(Row r) => DynamicQr(
    id: r['id'] as String,
    name: r['name'] as String,
    description: r['description'] as String,
    destinationUrl: r['destination_url'] as String,
    styleJson: r['style_json'] as String,
    active: (r['active'] as int) == 1,
    createdAt: DateTime.parse(r['created_at'] as String),
    updatedAt: DateTime.parse(r['updated_at'] as String),
  );

  String? _validateInput(String? id, DynamicQrInput input) {
    if (id != null) {
      final bad = validateShortId(id);
      if (bad.isNotEmpty) return bad.first.toString();
    }
    final errors = [
      ...validateQrName(input.name),
      ...validateDestinationUrl(input.destinationUrl),
    ];
    if (errors.isNotEmpty) return errors.first.toString();
    return null;
  }

  @override
  Future<Result<List<DynamicQr>>> list() async {
    final rows = db.select('SELECT * FROM qrs ORDER BY updated_at DESC;');
    return Ok(rows.map(_row).toList());
  }

  @override
  Future<Result<DynamicQr>> get(String id) async {
    final rows = db.select('SELECT * FROM qrs WHERE id = ?;', [id]);
    if (rows.isEmpty) return const Err('not found', code: 'not_found');
    return Ok(_row(rows.first));
  }

  @override
  Future<Result<DynamicQr>> create(String id, DynamicQrInput input) async {
    final bad = _validateInput(id, input);
    if (bad != null) return Err(bad, code: 'validation');
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      db.execute(
        'INSERT INTO qrs(id,name,description,destination_url,style_json,active,created_at,updated_at)'
        ' VALUES(?,?,?,?,?,?,?,?);',
        [
          id,
          input.name,
          input.description,
          input.destinationUrl,
          input.styleJson,
          input.active ? 1 : 0,
          now,
          now,
        ],
      );
    } on SqliteException catch (e) {
      if (e.extendedResultCode == 1555) {
        return const Err('id already exists', code: 'conflict');
      }
      rethrow;
    }
    return get(id);
  }

  @override
  Future<Result<DynamicQr>> update(String id, DynamicQrInput input) async {
    final existing = await get(id);
    if (existing is Err<DynamicQr>) return existing;
    final bad = _validateInput(null, input);
    if (bad != null) return Err(bad, code: 'validation');
    final now = DateTime.now().toUtc().toIso8601String();
    db.execute(
      'UPDATE qrs SET name=?,description=?,destination_url=?,style_json=?,active=?,updated_at=? WHERE id=?;',
      [
        input.name,
        input.description,
        input.destinationUrl,
        input.styleJson,
        input.active ? 1 : 0,
        now,
        id,
      ],
    );
    return get(id);
  }

  @override
  Future<Result<void>> delete(String id) async {
    db.execute('DELETE FROM qrs WHERE id = ?;', [id]);
    if (db.updatedRows == 0) {
      return const Err('not found', code: 'not_found');
    }
    db.execute('DELETE FROM scans WHERE qr_id = ?;', [id]);
    return const Ok(null);
  }

  @override
  Future<void> recordScan(String qrId, DateTime at) async {
    db.execute('INSERT INTO scans(qr_id,scanned_at) VALUES(?,?);', [
      qrId,
      at.toUtc().toIso8601String(),
    ]);
  }

  @override
  Future<ScanStats> stats(String qrId) async {
    final total = db.select(
      'SELECT COUNT(*) AS n FROM scans WHERE qr_id = ?;',
      [qrId],
    );
    final perDay = db.select(
      "SELECT substr(scanned_at,1,10) AS day, COUNT(*) AS n FROM scans"
      ' WHERE qr_id = ? GROUP BY day ORDER BY day;',
      [qrId],
    );
    return ScanStats(
      qrId: qrId,
      total: (total.first['n'] as int),
      perDay: {for (final r in perDay) r['day'] as String: r['n'] as int},
    );
  }

  void close() => db.dispose();
}
