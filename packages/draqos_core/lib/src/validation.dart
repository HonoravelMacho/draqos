/// Input validation for core entities. Pure Dart.
class ValidationError {
  final String field;
  final String message;
  const ValidationError(this.field, this.message);

  @override
  String toString() => '$field: $message';
}

final RegExp _shortId = RegExp(r'^[A-Za-z0-9_-]{3,32}$');

/// Short id rules: 3..32 chars, URL-safe.
List<ValidationError> validateShortId(String id) {
  if (!_shortId.hasMatch(id)) {
    return const [
      ValidationError(
        'id',
        'must be 3-32 chars long and URL-safe [A-Za-z0-9_-]',
      ),
    ];
  }
  return const [];
}

List<ValidationError> validateDestinationUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
    return const [
      ValidationError('destinationUrl', 'must be an absolute http(s) URL'),
    ];
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return const [
      ValidationError('destinationUrl', 'scheme must be http or https'),
    ];
  }
  return const [];
}

List<ValidationError> validateQrName(String name) {
  if (name.trim().isEmpty) {
    return const [ValidationError('name', 'must not be empty')];
  }
  if (name.length > 80) {
    return const [ValidationError('name', 'must be at most 80 chars')];
  }
  return const [];
}

/// Builds the stable public URL for a dynamic QR id.
String publicQrUrl(String base, String id) =>
    '${base.replaceAll(RegExp(r'/$'), '')}/r/$id';
