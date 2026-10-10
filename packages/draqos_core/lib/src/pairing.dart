/// Pairing payload exchanged when an Android editor joins a PC daemon.
/// Encoded as `draqos://pair?base=<url>&token=<token>&machine=<name>`.
class PairingPayload {
  final String baseUrl;
  final String token;
  final String machine;

  const PairingPayload({
    required this.baseUrl,
    required this.token,
    required this.machine,
  });

  String encode() {
    final q = Uri(
      scheme: 'draqos',
      host: 'pair',
      queryParameters: {'base': baseUrl, 'token': token, 'machine': machine},
    );
    return q.toString();
  }

  factory PairingPayload.decode(String raw) {
    final uri = Uri.parse(raw);
    if (uri.scheme != 'draqos' || uri.host != 'pair') {
      throw const FormatException('Not a DRAQOS pairing code');
    }
    final base = uri.queryParameters['base'];
    final token = uri.queryParameters['token'];
    if (base == null || base.isEmpty || token == null || token.isEmpty) {
      throw const FormatException('Pairing code misses base/token');
    }
    return PairingPayload(
      baseUrl: base,
      token: token,
      machine: uri.queryParameters['machine'] ?? '',
    );
  }
}
