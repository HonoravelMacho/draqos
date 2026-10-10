/// Domain entities for dynamic QR codes and scan statistics.
/// Pure Dart: no Flutter, no I/O.
class DynamicQr {
  final String id;
  final String name;
  final String description;
  final String destinationUrl;
  final String styleJson;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DynamicQr({
    required this.id,
    required this.name,
    required this.description,
    required this.destinationUrl,
    required this.styleJson,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  DynamicQr copyWith({
    String? name,
    String? description,
    String? destinationUrl,
    String? styleJson,
    bool? active,
    DateTime? updatedAt,
  }) {
    return DynamicQr(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      destinationUrl: destinationUrl ?? this.destinationUrl,
      styleJson: styleJson ?? this.styleJson,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'destinationUrl': destinationUrl,
    'styleJson': styleJson,
    'active': active,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory DynamicQr.fromJson(Map<String, dynamic> json) => DynamicQr(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    destinationUrl: json['destinationUrl'] as String,
    styleJson: json['styleJson'] as String? ?? '{}',
    active: json['active'] as bool? ?? true,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

/// Input payload for creating / updating a dynamic QR (no id/timestamps).
class DynamicQrInput {
  final String name;
  final String description;
  final String destinationUrl;
  final String styleJson;
  final bool active;

  const DynamicQrInput({
    required this.name,
    required this.description,
    required this.destinationUrl,
    required this.styleJson,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'destinationUrl': destinationUrl,
    'styleJson': styleJson,
    'active': active,
  };

  factory DynamicQrInput.fromJson(Map<String, dynamic> json) => DynamicQrInput(
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    destinationUrl: json['destinationUrl'] as String,
    styleJson: json['styleJson'] as String? ?? '{}',
    active: json['active'] as bool? ?? true,
  );
}

/// One scan event (no IP, no personal data — timestamp only).
class ScanEvent {
  final String qrId;
  final DateTime scannedAt;

  const ScanEvent({required this.qrId, required this.scannedAt});

  Map<String, dynamic> toJson() => {
    'qrId': qrId,
    'scannedAt': scannedAt.toIso8601String(),
  };
}

/// Aggregated scan statistics.
class ScanStats {
  final String qrId;
  final int total;
  final Map<String, int> perDay;

  const ScanStats({
    required this.qrId,
    required this.total,
    required this.perDay,
  });

  Map<String, dynamic> toJson() => {
    'qrId': qrId,
    'total': total,
    'perDay': perDay,
  };

  factory ScanStats.fromJson(Map<String, dynamic> json) => ScanStats(
    qrId: json['qrId'] as String,
    total: json['total'] as int? ?? 0,
    perDay: Map<String, int>.from(json['perDay'] as Map? ?? const {}),
  );
}

/// Admin pairing / status info returned by the daemon.
class DaemonStatus {
  final String hostname;
  final String tailnet;
  final bool funnelEnabled;
  final bool serveEnabled;
  final String version;

  const DaemonStatus({
    required this.hostname,
    required this.tailnet,
    required this.funnelEnabled,
    required this.serveEnabled,
    required this.version,
  });

  factory DaemonStatus.fromJson(Map<String, dynamic> json) => DaemonStatus(
    hostname: json['hostname'] as String? ?? '',
    tailnet: json['tailnet'] as String? ?? '',
    funnelEnabled: json['funnelEnabled'] as bool? ?? false,
    serveEnabled: json['serveEnabled'] as bool? ?? false,
    version: json['version'] as String? ?? '0.1.0',
  );

  Map<String, dynamic> toJson() => {
    'hostname': hostname,
    'tailnet': tailnet,
    'funnelEnabled': funnelEnabled,
    'serveEnabled': serveEnabled,
    'version': version,
  };
}
