// lib/core/network/network_exception.dart

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const NetworkException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  factory NetworkException.fromDioError(dynamic error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode as int?;
      final data = error.response!.data;
      String message = 'An unexpected error occurred.';
      String? errorCode;

      if (data is Map<String, dynamic>) {
        message = (data['message'] as String?) ?? message;
        errorCode = data['errorCode'] as String?;
      }

      switch (statusCode) {
        case 400:
          return NetworkException(
            message: message,
            statusCode: statusCode,
            errorCode: errorCode,
          );
        case 401:
          return NetworkException(
            message: 'Your session has expired. Please log in again.',
            statusCode: statusCode,
            errorCode: 'UNAUTHORIZED',
          );
        case 403:
          return NetworkException(
            message: 'You do not have permission to perform this action.',
            statusCode: statusCode,
            errorCode: 'FORBIDDEN',
          );
        case 404:
          return NetworkException(
            message: 'The requested resource was not found.',
            statusCode: statusCode,
            errorCode: 'NOT_FOUND',
          );
        case 409:
          return NetworkException(
            message: message,
            statusCode: statusCode,
            errorCode: errorCode ?? 'CONFLICT',
          );
        case 422:
          return NetworkException(
            message: message,
            statusCode: statusCode,
            errorCode: 'VALIDATION_ERROR',
          );
        case 429:
          return NetworkException(
            message:
                'Too many requests. Please wait a moment and try again.',
            statusCode: statusCode,
            errorCode: 'RATE_LIMITED',
          );
        case 500:
          return NetworkException(
            message:
                'Server error. Please try again later.',
            statusCode: statusCode,
            errorCode: 'SERVER_ERROR',
          );
        default:
          return NetworkException(
            message: message,
            statusCode: statusCode,
            errorCode: errorCode,
          );
      }
    } else if (error.type?.toString().contains('connectTimeout') ?? false) {
      return const NetworkException(
        message: 'Connection timed out. Please check your internet connection.',
        errorCode: 'TIMEOUT',
      );
    } else {
      return const NetworkException(
        message: 'Unable to connect to the server. Please check your internet connection.',
        errorCode: 'NO_CONNECTION',
      );
    }
  }

  @override
  String toString() => 'NetworkException: $message (${statusCode ?? errorCode})';
}
