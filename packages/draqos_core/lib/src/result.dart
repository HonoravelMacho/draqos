/// Minimal Result type (success / failure) used across core contracts.
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

final class Err<T> extends Result<T> {
  final String message;
  final String? code;
  const Err(this.message, {this.code});
}
