import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart';
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
      this.confirmedAs,
      String type = 'text'})
      : super(name, type, label: label, isRequired: isRequired);

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
  BoolField(String name,
      {String label, bool isRequired = true, String type = 'checkbox'})
      : super(name, type, label: label, isRequired: isRequired);

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
      {String label,
      String type = 'number',
      bool isRequired = true,
      this.max,
      this.min,
      this.step})
      : super(name, type, label: label, isRequired: isRequired) {
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
      {String label,
      String type = 'number',
      bool isRequired = true,
      num step,
      double min,
      double max})
      : super(name,
            type: type,
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
      {String label,
      String type = 'number',
      bool isRequired = true,
      num step = 1,
      int min,
      int max})
      : super(name,
            label: label,
            type: type,
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

/// A [Field] that parses its value as an ISO6801 [DateTime].
class DateTimeField extends Field<DateTime> {
  // Reuse text validation logic.
  TextField _textField;

  /// The minimum/maximum value for the field.
  final DateTime min, max;

  /// The amount for a form field to increment by.
  final num step;

  DateTimeField(String name,
      {String label,
      bool isRequired = true,
      this.max,
      this.min,
      this.step,
      String type = 'datetime-local'})
      : super(name, type, label: label, isRequired: isRequired) {
    _textField = TextField(name, label: label, isRequired: isRequired);
  }

  @override
  FutureOr<U> accept<U>(FormRenderer<U> renderer) =>
      renderer.visitDateTimeField(this);

  @override
  Future<FieldReadResult<DateTime>> read(RequestContext req,
      Map<String, dynamic> fields, Iterable<UploadedFile> files) async {
    var result = await _textField.read(req, fields, files);
    if (result == null) {
      return null;
    } else if (result.isSuccess != true) {
      return FieldReadResult.failure(result.errors);
    } else {
      var value = DateTime.tryParse(result.value);
      if (value != null) {
        return FieldReadResult.success(value);
      } else {
        return FieldReadResult.failure(
            ['"$name" must be a properly-formatted date.']);
      }
    }
  }
}

/// A [Field] that validates an [UploadedFile].
class FileField extends Field<UploadedFile> {
  /// If `true` (default), then the file must have a `content-type`.
  final bool requireContentType;

  /// If `true` (default: `false`), then the file must have an associated
  /// filename.
  final bool requireFilename;

  /// If provided, then the `content-type` must be present in this [Iterable].
  final Iterable<MediaType> allowedContentTypes;

  FileField(String name,
      {String label,
      bool isRequired = true,
      this.requireContentType = true,
      this.requireFilename = false,
      this.allowedContentTypes})
      : super(name, 'file', label: label, isRequired: isRequired) {
    assert(allowedContentTypes == null || allowedContentTypes.isNotEmpty);
  }

  @override
  FutureOr<U> accept<U>(FormRenderer<U> renderer) =>
      renderer.visitFileField(this);

  @override
  FutureOr<FieldReadResult<UploadedFile>> read(RequestContext req,
      Map<String, dynamic> fields, Iterable<UploadedFile> files) {
    var file = files.firstWhere((f) => f.name == name, orElse: () => null);
    if (file == null) {
      return null;
    } else if ((requireContentType || allowedContentTypes != null) &&
        file.contentType == null) {
      return FieldReadResult.failure(
          ['A content type must be given for file "$name".']);
    } else if (requireFilename && file.filename == null) {
      return FieldReadResult.failure(
          ['A filename must be given for file "$name".']);
    } else if (allowedContentTypes != null &&
        !allowedContentTypes.contains(file.contentType)) {
      return FieldReadResult.failure([
        'File "$name" cannot have content type '
            '"${file.contentType}". Allowed types: '
            '${allowedContentTypes.join(', ')}'
      ]);
    } else {
      return FieldReadResult.success(file);
    }
  }
}

/// A wrapper around [FileField] that reads its input into an [Image].
///
/// **CAUTION**: The uploaded file will be read in memory.
class ImageField extends Field<Image> {
  FileField _fileField;

  /// The underlying [FileField].
  FileField get fileField => _fileField;

  ImageField(String name,
      {String label,
      bool isRequired = true,
      bool requireContentType = true,
      bool requireFilename = false,
      Iterable<MediaType> allowedContentTypes})
      : super(name, 'file', label: label, isRequired: isRequired) {
    _fileField = FileField(name,
        label: label,
        isRequired: isRequired,
        requireContentType: requireContentType,
        requireFilename: requireFilename,
        allowedContentTypes: allowedContentTypes);
  }

  @override
  FutureOr<U> accept<U>(FormRenderer<U> renderer) =>
      renderer.visitImageField(this);

  @override
  FutureOr<FieldReadResult<Image>> read(RequestContext req,
      Map<String, dynamic> fields, Iterable<UploadedFile> files) async {
    var result = await fileField.read(req, fields, files);
    if (result == null) {
      return null;
    } else if (!result.isSuccess) {
      return FieldReadResult.failure(result.errors);
    } else {
      try {
        var image = decodeImage(await result.value.readAsBytes());
        if (image == null) {
          return FieldReadResult.failure(['"$name" must be an image file.']);
        } else {
          return FieldReadResult.success(image);
        }
      } on ImageException catch (e) {
        return FieldReadResult.failure(
            ['Error in image file "$name": ${e.message}']);
      }
    }
  }
}
