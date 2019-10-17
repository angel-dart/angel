import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'field.dart';
import 'form_renderer.dart';

/// A [Field] that accepts plain text.
class TextField extends Field<String> {
  /// If `true` (default), then renderers will produce a `<textarea>` element.
  final bool isTextArea;

  /// If `true` (default), then the input will be trimmed before validation.
  final bool trim;

  /// If not `null`, then if the value of [confirmedAs] in the body is not
  /// identical, an error will be returned.
  final String confirmedAs;

  TextField(String name,
      {String label,
      bool isRequired = true,
      this.isTextArea = false,
      this.trim = true,
      this.confirmedAs})
      : super(name, label: label, isRequired: isRequired);

  @override
  FutureOr<U> accept<U>(FormRenderer<U> renderer) =>
      renderer.visitTextField(this);

  String _normalize(String s) {
    if (trim) {
      s = s?.trim();
    }
    return s;
  }

  @override
  FutureOr<FieldReadResult<String>> read(RequestContext req,
      Map<String, dynamic> fields, Iterable<UploadedFile> files) {
    var value = _normalize(fields[name] as String);
    if (value == null) {
      return null;
    } else if (trim && value.isEmpty) {
      return null;
    } else {
      if (confirmedAs != null) {
        var confirmed = _normalize(fields[confirmedAs] as String);
        if (confirmed != value) {
          return FieldReadResult.failure(
              ['"$name" and "$confirmedAs" must be identical.']);
        }
      }

      return FieldReadResult.success(value);
    }
  }
}

/// A [Field] that checks simply for its presence in the given data.
/// Typically used for checkboxes.
class BoolField extends Field<bool> {
  BoolField(String name, {String label, bool isRequired = true})
      : super(name, label: label, isRequired: isRequired);

  @override
  FutureOr<U> accept<U>(FormRenderer<U> renderer) =>
      renderer.visitBoolField(this);

  @override
  FutureOr<FieldReadResult<bool>> read(RequestContext req,
      Map<String, dynamic> fields, Iterable<UploadedFile> files) {
    if (fields.containsKey(name)) {
      return FieldReadResult.success(true);
    } else {
      return FieldReadResult.success(false);
    }
  }
}

/// A [Field] that parses its value as a [num].
class NumField<T extends num> extends Field<T> {
  // Reuse text validation logic.
  TextField _textField;

  /// The minimum/maximum value for the field.
  final T min, max;

  /// The amount for a form field to increment by.
  final num step;

  NumField(String name,
      {String label, bool isRequired = true, this.max, this.min, this.step})
      : super(name, label: label, isRequired: isRequired) {
    _textField = TextField(name, label: label, isRequired: isRequired);
  }

  @override
  FutureOr<U> accept<U>(FormRenderer<U> renderer) =>
      renderer.visitNumField(this);

  @override
  Future<FieldReadResult<T>> read(RequestContext req,
      Map<String, dynamic> fields, Iterable<UploadedFile> files) async {
    var result = await _textField.read(req, fields, files);
    if (result == null) {
      return null;
    } else if (result.isSuccess != true) {
      return FieldReadResult.failure(result.errors);
    } else {
      var value = num.tryParse(result.value);
      if (value != null) {
        if (min != null && value < min) {
          return FieldReadResult.failure(['"$name" can be no less than $min.']);
        } else if (max != null && value > max) {
          return FieldReadResult.failure(
              ['"$name" can be no greater than $max.']);
        } else {
          return FieldReadResult.success(value as T);
        }
      } else {
        return FieldReadResult.failure(['"$name" must be a number.']);
      }
    }
  }
}

/// A [NumField] that coerces its value to a [double].
class DoubleField extends NumField<double> {
  DoubleField(String name,
      {String label, bool isRequired = true, num step, double min, double max})
      : super(name,
            label: label,
            isRequired: isRequired,
            step: step,
            min: min,
            max: max);

  @override
  Future<FieldReadResult<double>> read(RequestContext req,
      Map<String, dynamic> fields, Iterable<UploadedFile> files) async {
    var result = await super.read(req, fields, files);
    if (result == null) {
      return null;
    } else if (!result.isSuccess) {
      return FieldReadResult.failure(result.errors);
    } else {
      return FieldReadResult.success(result.value.toDouble());
    }
  }
}

/// A [NumField] that requires its value to be an [int].
/// Passing a [double] will result in an error, so [step] defaults to 1.
class IntField extends NumField<int> {
  IntField(String name,
      {String label, bool isRequired = true, num step = 1, int min, int max})
      : super(name,
            label: label,
            isRequired: isRequired,
            step: step,
            min: min,
            max: max);

  @override
  Future<FieldReadResult<int>> read(RequestContext req,
      Map<String, dynamic> fields, Iterable<UploadedFile> files) async {
    var result = await super.read(req, fields, files);
    if (result == null) {
      return null;
    } else if (!result.isSuccess) {
      return FieldReadResult.failure(result.errors);
    } else {
      var value = result.value;
      if (value is int) {
        return FieldReadResult.success(result.value);
      } else {
        return FieldReadResult.failure(['"$name" must be an integer.']);
      }
    }
  }
}
