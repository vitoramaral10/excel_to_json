/// Thrown when a spreadsheet cannot be converted.
class ExcelToJsonException implements Exception {
  /// Creates the exception with a [message] and the error that caused it.
  const ExcelToJsonException(this.message, [this.cause]);

  /// What went wrong.
  final String message;

  /// The underlying error, if any.
  final Object? cause;

  @override
  String toString() => 'ExcelToJsonException: $message'
      '${cause != null ? ' (Caused by: $cause)' : ''}';
}
