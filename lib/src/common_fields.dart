import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'field.dart';
import 'form_renderer.dart';

/// A [Field] that accepts plain text.
class TextField extends Field<String> {
  /// If `true`, then renderers will produce a `<textarea>` element.
  final bool isTextArea;

  TextField(String name,
      {String label, bool isRequired = false, this.isTextArea = false})
      : super(name, label: label, isRequired: isRequired);

  @override
  FutureOr<U> accept<U>(FormRenderer<U> renderer) =>
      renderer.visitTextField(this);

  @override
  FutureOr<FieldReadResult<String>> read(RequestContext req) {
    var value = req.bodyAsMap[name] as String;
    if (value == null) {
      return null;
    } else {
      return FieldReadResult.success(value);
    }
  }
}

/// A [Field] that checks simply for its presence in the given data.
/// Typically used for checkboxes.
class BoolField extends Field<bool> {
  BoolField(String name, {String label, bool isRequired = false})
      : super(name, label: label, isRequired: isRequired);

  @override
  FutureOr<U> accept<U>(FormRenderer<U> renderer) =>
      renderer.visitBoolField(this);

  @override
  FutureOr<FieldReadResult<bool>> read(RequestContext req) {
    if (req.bodyAsMap.containsKey(name)) {
      return FieldReadResult.success(true);
    } else if (!isRequired) {
      return FieldReadResult.success(false);
    } else {
      return null;
    }
  }
}
