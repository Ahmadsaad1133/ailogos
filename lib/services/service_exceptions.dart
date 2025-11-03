/// Base class for service level exceptions that can be surfaced to the UI.
class AppServiceException implements Exception {
  final String message;
  const AppServiceException(this.message);

  @override
  String toString() => message;
}

/// Thrown when an API key is not configured for the active provider.
class MissingApiKeyException extends AppServiceException {
  const MissingApiKeyException()
      : super('Missing API key. Please configure your OpenAI key to continue.');
}

/// Thrown when the upstream AI provider returns an error response.
class ProviderException extends AppServiceException {
  final int statusCode;
  const ProviderException({required String message, required this.statusCode})
      : super(message);
}