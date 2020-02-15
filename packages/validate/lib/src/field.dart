import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:matcher/matcher.dart';
import 'form.dart';
import 'form_renderer.dart';

/// Holds the result of validating a field.
class FieldReadResult<T> {
  /// If `true`, then validation was successful.
  /// If `false`, [errors] must not be empty.
  final bool isSuccess;

  /// The value provided by the user.
  final T value;

  /// Any errors that arose during validation.
  final Iterable<String> errors;

  FieldReadResult.success(this.value)
      : isSuccess = true,
        errors = [];

  FieldReadResult.failure(this.errors)
      : isSuccess = false,
        value = null;
}

/// An abstraction used to fetch values from request bodies, in a type-safe manner.
abstract class Field<T> {
  /// The name of this field. This is the name that users should include in
  /// request bodies.
  final String name;

  /// An optional label for the field.
  final String label;

  /// Whether the field is required. If `true`, then if it is not
  /// present, an error will be generated.
  final bool isRequired;

  /// The input `type` attribute, if applicable.
  final String type;

  Field(this.name, this.type, {this.label, this.isRequired = true});

  /// Reads the value from the request body.
  ///
  /// If it returns `null` and [isRequired] is `true`, an error must
  /// be generated.
  FutureOr<FieldReadResult<T>> read(RequestContext req,
      Map<String, dynamic> fields, Iterable<UploadedFile> files);

  /// Accepts a form renderer.
  FutureOr<U> accept<U>(FormRenderer<U> renderer);

  /// Wraps this instance in one that throws an error if any of the
  /// [matchers] fails.
  Field<T> match(Iterable<Matcher> matchers) => _MatchedField(this, matchers);

  /// Calls [read], and returns the retrieve value from the body.
  ///
  /// If [query] is `true` (default: `false`), then the value will
  /// be read from the request `queryParameters` instead.
  ///
  /// If there is an error, then an [AngelHttpException] is thrown.
  /// If a [defaultValue] is provided, it will be returned in case of an
  /// error or missing value.
  Future<T> getValue(RequestContext req,
      {String errorMessage, T defaultValue, bool query = false}) async {
    var uploadedFiles = <UploadedFile>[];
    if (req.hasParsedBody || !query) {
      await req.parseBody();
      uploadedFiles = req.uploadedFiles;
    }
    var result = await read(
        req, query ? req.queryParameters : req.bodyAsMap, uploadedFiles);
    if (result?.isSuccess != true && defaultValue != null) {
      return defaultValue;
    } else if (result == null) {
      errorMessage ??= Form.reportMissingField(name, query: query);
      throw AngelHttpException.badRequest(message: errorMessage);
    } else if (!result.isSuccess) {
      errorMessage ??= result.errors.first;
      throw AngelHttpException.badRequest(
          message: errorMessage, errors: result.errors.toList());
    } else {
      return result.value;
    }
  }
}

class _MatchedField<T> extends Field<T> {
  final Field<T> inner;
  final Iterable<Matcher> matchers;

  _MatchedField(this.inner, this.matchers)
      : super(inner.name, inner.type,
            label: inner.label, isRequired: inner.isRequired) {
    assert(matchers.isNotEmpty);
  }

  @override
  FutureOr<U> accept<U>(FormRenderer<U> renderer) => inner.accept(renderer);

  @override
  Future<FieldReadResult<T>> read(RequestContext req,
      Map<String, dynamic> fields, Iterable<UploadedFile> files) async {
    var result = await inner.read(req, fields, files);
    if (!result.isSuccess) {
      return result;
    } else {
      var errors = <String>[];
      for (var matcher in matchers) {
        if (!matcher.matches(result.value, {})) {
          var desc = matcher.describe(StringDescription());
          errors.add('Expected $desc for field "${inner.name}".');
        }
      }
      if (errors.isEmpty) {
        return result;
      } else {
        return FieldReadResult.failure(errors);
      }
    }
  }
}
