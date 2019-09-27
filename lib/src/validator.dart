import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:matcher/matcher.dart';
import 'context_aware.dart';
import 'context_validator.dart';

final RegExp _asterisk = RegExp(r'\*$');
final RegExp _forbidden = RegExp(r'!$');
final RegExp _optional = RegExp(r'\?$');

/// Returns a value based the result of a computation.
typedef DefaultValueFunction();

/// Generates an error message based on the given input.
typedef String CustomErrorMessageFunction(item);

/// Determines if a value is valid.
typedef bool Filter(value);

/// Converts the desired fields to their numeric representations, if present.
Map<String, dynamic> autoParse(Map inputData, Iterable<String> fields) {
  Map<String, dynamic> data = {};

  for (var key in inputData.keys) {
    if (!fields.contains(key)) {
      data[key.toString()] = inputData[key];
    } else {
      try {
        var n = inputData[key] is num
            ? inputData[key]
            : num.parse(inputData[key].toString());
        data[key.toString()] = n == n.toInt() ? n.toInt() : n;
      } catch (e) {
        // Invalid number, don't pass it
      }
    }
  }

  return data;
}

/// Removes undesired fields from a `Map`.
Map<String, dynamic> filter(Map inputData, Iterable<String> only) {
  return inputData.keys.fold(<String, dynamic>{}, (map, key) {
    if (only.contains(key.toString())) map[key.toString()] = inputData[key];
    return map;
  });
}

/// Enforces the validity of input data, according to [Matcher]s.
class Validator extends Matcher {
  /// Pre-defined error messages for certain fields.
  final Map<String, dynamic> customErrorMessages = {};

  /// Values that will be filled for fields if they are not present.
  final Map<String, dynamic> defaultValues = {};

  /// Fields that cannot be present in valid data.
  final List<String> forbiddenFields = [];

  /// Conditions that must be met for input data to be considered valid.
  final Map<String, List<Matcher>> rules = {};

  /// Fields that must be present for data to be considered valid.
  final List<String> requiredFields = [];

  void _importSchema(Map<String, dynamic> schema) {
    for (var keys in schema.keys) {
      for (var key in keys.split(',').map((s) => s.trim())) {
        var fieldName = key
            .replaceAll(_asterisk, '')
            .replaceAll(_forbidden, '')
            .replaceAll(_optional, '');
        var isForbidden = _forbidden.hasMatch(key),
            isRequired = _asterisk.hasMatch(key);

        if (isForbidden) {
          forbiddenFields.add(fieldName);
        } else if (isRequired) {
          requiredFields.add(fieldName);
        }

        var _iterable =
            schema[keys] is Iterable ? schema[keys] : [schema[keys]];
        var iterable = [];

        _addTo(x) {
          if (x is Iterable) {
            x.forEach(_addTo);
          } else {
            iterable.add(x);
          }
        }

        _iterable.forEach(_addTo);

        for (var rule in iterable) {
          if (rule is Matcher) {
            addRule(fieldName, rule);
          } else if (rule is Filter) {
            addRule(fieldName, predicate(rule));
          } else {
            addRule(fieldName, wrapMatcher(rule));
          }
        }
      }
    }
  }

  Validator.empty();

  Validator(Map<String, dynamic> schema,
      {Map<String, dynamic> defaultValues = const {},
      Map<String, dynamic> customErrorMessages = const {}}) {
    this.defaultValues.addAll(defaultValues ?? {});
    this.customErrorMessages.addAll(customErrorMessages ?? {});
    _importSchema(schema);
  }

  static bool _hasContextValidators(Iterable it) =>
      it.any((x) => x is ContextValidator);

  /// Validates, and filters input data.
  ValidationResult check(Map inputData) {
    List<String> errors = [];
    var input = Map.from(inputData);
    Map<String, dynamic> data = {};

    for (String key in defaultValues.keys) {
      if (!input.containsKey(key)) {
        var value = defaultValues[key];
        input[key] = value is DefaultValueFunction ? value() : value;
      }
    }

    for (String field in forbiddenFields) {
      if (input.containsKey(field)) {
        if (!customErrorMessages.containsKey(field)) {
          errors.add("'$field' is forbidden.");
        } else {
          errors.add(customError(field, input[field]));
        }
      }
    }

    for (String field in requiredFields) {
      if (!_hasContextValidators(rules[field] ?? [])) {
        if (!input.containsKey(field)) {
          if (!customErrorMessages.containsKey(field)) {
            errors.add("'$field' is required.");
          } else {
            errors.add(customError(field, 'none'));
          }
        }
      }
    }

    // Run context validators.

    for (var key in input.keys) {
      if (key is String && rules.containsKey(key)) {
        var valid = true;
        var value = input[key];
        var description = StringDescription("'$key': expected ");

        for (var matcher in rules[key]) {
          if (matcher is ContextValidator) {
            if (!matcher.validate(key, input)) {
              errors.add(matcher
                  .errorMessage(description, key, input)
                  .toString()
                  .trim());
              valid = false;
            }
          }
        }

        if (valid) {
          for (Matcher matcher in rules[key]) {
            try {
              if (matcher is Validator) {
                var result = matcher.check(value as Map);

                if (result.errors.isNotEmpty) {
                  errors.addAll(result.errors);
                  valid = false;
                  break;
                }
              } else {
                bool result;

                if (matcher is ContextAwareMatcher) {
                  result = matcher.matchesWithContext(value, key, input, {});
                } else {
                  result = matcher.matches(value, {});
                }

                if (!result) {
                  if (!customErrorMessages.containsKey(key)) {
                    errors.add(matcher.describe(description).toString().trim());
                  }
                  valid = false;
                  break;
                }
              }
            } catch (e) {
              errors.add(e.toString());
              valid = false;
              break;
            }
          }
        }

        if (valid) {
          data[key] = value;
        } else if (customErrorMessages.containsKey(key)) {
          errors.add(customError(key, input[key]));
        }
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult().._errors.addAll(errors);
    }

    return ValidationResult().._data.addAll(data);
  }

  /// Validates, and filters input data after running [autoParse].
  ValidationResult checkParsed(Map inputData, List<String> fields) =>
      check(autoParse(inputData, fields));

  /// Renders the given custom error.
  String customError(String key, value) {
    if (!customErrorMessages.containsKey(key)) {
      throw ArgumentError("No custom error message registered for '$key'.");
    }

    var msg = customErrorMessages[key];

    if (msg is String) {
      return msg.replaceAll('{{value}}', value.toString());
    } else if (msg is CustomErrorMessageFunction) {
      return msg(value);
    }

    throw ArgumentError("Invalid custom error message '$key': $msg");
  }

  /// Validates input data, and throws an error if it is invalid.
  ///
  /// Otherwise, the filtered data is returned.
  Map<String, dynamic> enforce(Map inputData,
      {String errorMessage = 'Invalid data.'}) {
    var result = check(inputData);

    if (result._errors.isNotEmpty) {
      throw ValidationException(errorMessage, errors: result._errors);
    }

    return result.data;
  }

  /// Validates, and filters input data after running [autoParse], and throws an error if it is invalid.
  ///
  /// Otherwise, the filtered data is returned.
  Map<String, dynamic> enforceParsed(Map inputData, List<String> fields) =>
      enforce(autoParse(inputData, fields));

  /// Creates a copy with additional validation rules.
  Validator extend(Map<String, dynamic> schema,
      {Map<String, dynamic> defaultValues = const {},
      Map<String, dynamic> customErrorMessages = const {},
      bool overwrite = false}) {
    Map<String, dynamic> _schema = {};
    var child = Validator.empty()
      ..defaultValues.addAll(this.defaultValues)
      ..defaultValues.addAll(defaultValues ?? {})
      ..customErrorMessages.addAll(this.customErrorMessages)
      ..customErrorMessages.addAll(customErrorMessages ?? {})
      ..requiredFields.addAll(requiredFields)
      ..rules.addAll(rules);

    for (var key in schema.keys) {
      var fieldName = key
          .replaceAll(_asterisk, '')
          .replaceAll(_forbidden, '')
          .replaceAll(_optional, '');
      var isForbidden = _forbidden.hasMatch(key);
      var isOptional = _optional.hasMatch(key);
      var isRequired = _asterisk.hasMatch(key);

      if (isForbidden) {
        child
          ..requiredFields.remove(fieldName)
          ..forbiddenFields.add(fieldName);
      } else if (isOptional) {
        child
          ..forbiddenFields.remove(fieldName)
          ..requiredFields.remove(fieldName);
      } else if (isRequired) {
        child
          ..forbiddenFields.remove(fieldName)
          ..requiredFields.add(fieldName);
      }

      if (overwrite) {
        if (child.rules.containsKey(fieldName)) child.rules.remove(fieldName);
      }

      _schema[fieldName] = schema[key];
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
    enforce(item as Map);
    return true;
  }

  @override
  String toString() => 'Validation schema: $rules';
}

/// The result of attempting to validate input data.
class ValidationResult {
  final Map<String, dynamic> _data = {};
  final List<String> _errors = [];

  /// The successfully validated data, filtered from the original input.
  Map<String, dynamic> get data => Map<String, dynamic>.unmodifiable(_data);

  /// A list of errors that resulted in the given data being marked invalid.
  ///
  /// This is empty if validation was successful.
  List<String> get errors => List<String>.unmodifiable(_errors);

  ValidationResult withData(Map<String, dynamic> data) =>
      ValidationResult().._data.addAll(data).._errors.addAll(_errors);

  ValidationResult withErrors(Iterable<String> errors) =>
      ValidationResult().._data.addAll(_data).._errors.addAll(errors);
}

/// Occurs when user-provided data is invalid.
class ValidationException extends AngelHttpException {
  /// A list of errors that resulted in the given data being marked invalid.
  final List<String> errors = [];

  /// A descriptive message describing the error.
  final String message;

  ValidationException(this.message, {Iterable<String> errors = const []})
      : super(FormatException(message),
            statusCode: 400,
            errors: (errors ?? <String>[]).toSet().toList(),
            stackTrace: StackTrace.current) {
    if (errors != null) this.errors.addAll(errors.toSet());
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
