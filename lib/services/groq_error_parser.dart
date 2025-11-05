import 'dart:convert';

import 'service_exceptions.dart';

class GroqErrorParser {
  const GroqErrorParser._();

  static AppServiceException parse(int statusCode, String body) {
    if (body.isEmpty) {
      return ProviderException(
        statusCode: statusCode,
        message: 'Groq error $statusCode',
      );
    }

    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'] as String?;
          final type = error['type'] as String?;
          final code = error['code'] as String?;

          final buffer = StringBuffer();
          if (message != null && message.isNotEmpty) {
            buffer.write(message);
          } else {
            buffer.write('Groq error $statusCode');
          }

          if (code != null && code.isNotEmpty) {
            buffer.write(' (code: $code)');
          }

          if (type != null && type.isNotEmpty) {
            buffer.write(' [$type]');
          }

          return ProviderException(
            statusCode: statusCode,
            message: buffer.toString(),
          );
        }
      }
    } catch (_) {
      // ignore parsing failures and fall back to raw body below
    }

    return ProviderException(
      statusCode: statusCode,
      message: 'Groq error $statusCode: $body',
    );
  }
}