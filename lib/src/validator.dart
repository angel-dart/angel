import 'package:matcher/matcher.dart';

final RegExp _asterisk = new RegExp(r'\*$');
final RegExp _optional = new RegExp(r'\?$');

/// Returns a value based the result of a computation.
typedef DefaultValueFunction();

/// Determines if a value is valid.
typedef bool Filter(value);

/// Enforces the validity of input data, according to [Matcher]s.
class Validator extends Matcher {
  /// Values that will be filled for fields if they are not present.
  final Map<String, dynamic> defaultValues = {};

  /// Conditions that must be met for input data to be considered valid.
  final Map<String, List<Matcher>> rules = {};

  /// Fields that must be present for data to be considered valid.
  final List<String> requiredFields = [];

  void _importSchema(Map<String, dynamic> schema) {
    for (var key in schema.keys) {
      var fieldName = key.replaceAll(_asterisk, '');
      var isRequired = _asterisk.hasMatch(key);

      if (isRequired) {
        requiredFields.add(fieldName);
      }

      Iterable iterable = schema[key] is Iterable ? schema[key] : [schema[key]];

      for (var rule in iterable) {
        if (rule is Matcher) {
          addRule(fieldName, rule);
        } else if (rule is Filter) {
          addRule(fieldName, predicate(rule));
        } else {
          throw new ArgumentError(
              'Cannot use a(n) ${rule.runtimeType} as a validation rule.');
        }
      }
    }
  }

  Validator.empty();

  Validator(Map<String, dynamic> schema,
      {Map<String, dynamic> defaultValues: const {}}) {
    this.defaultValues.addAll(defaultValues ?? {});
    _importSchema(schema);
  }

  /// Validates, and filters input data.
  ValidationResult check(Map inputData) {
    List<String> errors = [];
    var input = new Map.from(inputData);
    Map<String, dynamic> data = {};

    for (String key in defaultValues.keys) {
      if (!input.containsKey(key)) {
        var value = defaultValues[key];
        input[key] = value is DefaultValueFunction ? value() : value;
      }
    }

    for (String field in requiredFields) {
      if (!input.containsKey(field)) {
        errors.add("'$field' is required.");
      }
    }

    for (var key in input.keys) {
      if (key is String && rules.containsKey(key)) {
        var valid = true;
        var value = input[key];
        var description = new StringDescription("Field '$key': expected ");

        for (Matcher matcher in rules[key]) {
          try {
            if (matcher is Validator) {
              var result = matcher.check(value);

              if (result.errors.isNotEmpty) {
                errors.addAll(result.errors);
                valid = false;
              }
            } else {
              if (!matcher.matches(value, {})) {
                errors.add(matcher.describe(description).toString().trim());
                valid = false;
              }
            }
          } catch (e) {
            errors.add(e.toString());
            valid = false;
          }
        }

        if (valid) {
          data[key] = value;
        }
      }
    }

    if (errors.isNotEmpty) {
      return new ValidationResult().._errors.addAll(errors);
    }

    return new ValidationResult().._data = data;
  }

  /// Validates input data, and throws an error if it is invalid.
  ///
  /// Otherwise, the filtered data is returned.
  Map<String, dynamic> enforce(Map inputData,
      {String errorMessage: 'Invalid data.'}) {
    var result = check(inputData);

    if (result._errors.isNotEmpty) {
      throw new ValidationException(errorMessage, errors: result._errors);
    }

    return result.data;
  }

  /// Creates a copy with additional validation rules.
  Validator extend(Map<String, dynamic> schema,
      {Map<String, dynamic> defaultValues: const {}, bool overwrite: false}) {
    Map<String, dynamic> _schema = {};
    var child = new Validator.empty()
      ..defaultValues.addAll(this.defaultValues)
      ..defaultValues.addAll(defaultValues ?? {})
      ..requiredFields.addAll(requiredFields)
      ..rules.addAll(rules);

    if (overwrite) {
      for (var key in schema.keys) {
        var fieldName = key.replaceAll(_asterisk, '').replaceAll(_optional, '');
        var isOptional = _optional.hasMatch(key);
        var isRequired = _asterisk.hasMatch(key);

        if (isOptional)
          child.requiredFields.remove(fieldName);
        else if (isRequired) child.requiredFields.add(fieldName);

        if (child.rules.containsKey(key)) child.rules.remove(key);

        _schema[fieldName] = schema[key];
      }
    } else {
      for (var key in schema.keys) {
        var fieldName = key.replaceAll(_asterisk, '').replaceAll(_optional, '');
        var isOptional = _optional.hasMatch(key);
        var isRequired = _asterisk.hasMatch(key);

        if (isOptional)
          child.requiredFields.remove(fieldName);
        else if (isRequired) child.requiredFields.add(fieldName);

        _schema[fieldName] = schema[key];
      }
    }

    return child.._importSchema(_schema);
  }

  /// Adds a [rule].
  void addRule(String key, Matcher rule) {
    if (!rules.containsKey(key)) {
      rules[key] = [rule];
      return;
    }

    rules[key].add(rule);
  }

  /// Adds all given [rules].
  void addRules(String key, Iterable<Matcher> rules) {
    rules.forEach((rule) => addRule(key, rule));
  }

  /// Removes a [rule].
  void removeRule(String key, Matcher rule) {
    if (rules.containsKey(key)) {
      rules[key].remove(rule);
    }
  }

  /// Removes all given [rules].
  void removeRules(String key, Iterable<Matcher> rules) {
    rules.forEach((rule) => removeRule(key, rule));
  }

  @override
  Description describe(Description description) =>
      description.add(' passes the provided validation schema: $rules');

  @override
  bool matches(item, Map matchState) {
    enforce(item);
    return true;
  }

  @override
  String toString() => 'Validation schema: $rules';
}

/// The result of attempting to validate input data.
class ValidationResult {
  Map<String, dynamic> _data;
  final List<String> _errors = [];

  /// The successfully validated data, filtered from the original input.
  Map<String, dynamic> get data => _data;

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
  String toString() {
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
