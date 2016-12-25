/// Enforces the validity of input data, according to [Matcher]s.
class Validator {
  /// Validates, and filters input data.
  ValidationResult check(Map inputData) {}

  /// Validates input data, and throws an error if it is invalid.
  /// 
  /// Otherwise, the filtered data is returned.
  Map enforce(Map inputData, {String errorMessage: 'Invalid data.'}) {}
}

/// The result of attempting to validate input data.
class ValidationResult {
  Map _data;
  final List<String> _errors = [];

  /// The successfully validated data, filtered from the original input.
  Map get data => _data;

  /// A list of errors that resulted in the given data being marked invalid.
  /// 
  /// This is empty if validation was successful.
  List<String> get errors => new List<String>.unmodifiable(_errors);
}

/// Occurs when user-provided data is invalid.
class ValidationException {
  /// A list of errors that resulted in the given data being marked invalid.
  final List<String> errors = [];

  /// A descriptive message describing the error.
  final String message;

  ValidationException(this.message, {List<String> errors: const []}) {
    if (errors != null) this.errors.addAll(errors);
  }

  @override
  String get toString {
    if (errors.isEmpty) {
      return message;
    }

    if (errors.length == 1) {
      return 'Validation error: ${errors.first}';
    }

    var messages = ['${errors.length} validation errors:\n']
      ..addAll(errors.map((error) => '* $error'));

    return messages.join('\n');
  }
}
