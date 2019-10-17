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

  TextField(String name,
      {String label,
      bool isRequired = true,
      this.isTextArea = false,
      this.trim = true})
      : super(name, label: label, isRequired: isRequired);

  @override
  FutureOr<U> accept<U>(FormRenderer<U> renderer) =>
      renderer.visitTextField(this);

  @override
  FutureOr<FieldReadResult<String>> read(
      Map<String, dynamic> fields, Iterable<UploadedFile> files) {
    var value = fields[name] as String;
    if (trim) {
      value = value?.trim();
    }
    if (value == null) {
      return null;
    } else if (trim && value.isEmpty) {
      return null;
    } else {
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
  FutureOr<FieldReadResult<bool>> read(
      Map<String, dynamic> fields, Iterable<UploadedFile> files) {
    if (fields.containsKey(name)) {
      return FieldReadResult.success(true);
    } else {
      return FieldReadResult.success(false);
    }
  }
}
