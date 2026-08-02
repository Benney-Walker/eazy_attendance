/// Typed errors surfaced by the networking + repository layers, so the UI can
/// show the right message without inspecting Dio internals.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  /// Human-readable, display-safe message.
  final String message;

  @override
  String toString() => 'ApiException: $message';
}

/// The device could not reach the server (no network, timeout, DNS, etc.).
/// Mirrors the website's "Could not connect to server" branch.
class NetworkException extends ApiException {
  const NetworkException(
      [super.message = 'Could not connect to server. Please try again later.']);
}

/// The server rejected the credentials / token (HTTP 401).
class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Invalid credentials.']);
}

/// The server returned an error status (500 or other non-2xx).
class ServerException extends ApiException {
  const ServerException([super.message = 'Server error.', this.statusCode]);

  final int? statusCode;
}

/// Anything else we did not specifically classify.
class UnexpectedException extends ApiException {
  const UnexpectedException(
      [super.message = 'An unexpected error occurred.']);
}
