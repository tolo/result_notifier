/// Base class for all exceptions used by ResultNotifier.
class ResultNotifierException implements Exception {
  ResultNotifierException({required this.message});

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception thrown when a ResultNotifier is disposed.
class DisposedException extends ResultNotifierException {
  DisposedException() : super(message: 'ResultNotifier is disposed');
}

/// Exception thrown when data is not available (or failed to fetch) and no other error is available.
class NoDataException extends ResultNotifierException {
  NoDataException() : super(message: 'No data');
}

/// Exception thrown when a data fetch operation is cancelled.
class CancelledException extends ResultNotifierException {
  CancelledException() : super(message: 'Cancelled');
}
