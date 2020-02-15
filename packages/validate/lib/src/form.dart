import 'dart:async';
import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:matcher/matcher.dart';
import 'field.dart';

/// A utility that combines multiple [Field]s to read and
/// validate web forms in a type-safe manner.
///
/// Example:
/// ```dart
/// import 'package:angel_validate/angel_validate.dart';
///
/// var myForm = Form(fields: [
///   TextField('username').match([minLength(8)]),
///   TextField('password', confirmedAs: 'confirm_password'),
/// ])
///
/// app.post('/login', (req, res) async {
///   var loginBody =
///     await myForm.decode(req, loginBodySerializer);
///   // Do something with the decoded object...
/// });
/// ```
class Form {
  /// A custom error message to provide the user if validation fails.
  final String errorMessage;

  final List<Field> _fields = [];

  static const String defaultErrorMessage =
      'There were errors in your submission. '
      'Please make sure all fields entered correctly, and submit it again.';

  /// Computes an error message in the case of a missing required field.
  static String reportMissingField(String fieldName, {bool query = false}) {
    var type = query ? 'query parameter' : 'field';
    return 'The $type "$fieldName" is required.';
  }

  Form({this.errorMessage = defaultErrorMessage, Iterable<Field> fields}) {
    fields?.forEach(addField);
  }

  /// Returns the fields in this form.
  List<Field> get fields => _fields;

  /// Helper for adding fields. Passing [matchers] will result in them
  /// being applied to the [field].
  Field<T> addField<T>(Field<T> field, {Iterable<Matcher> matchers}) {
    if (matchers != null) {
      field = field.match(matchers);
    }
    _fields.add(field);
    return field;
  }

  /// Deserializes the result of calling [validate].
  ///
  /// If [query] is `true` (default: `false`), then the value will
  /// be read from the request `queryParameters` instead.
  Future<T> deserialize<T>(
      RequestContext req, T Function(Map<String, dynamic>) f,
      {bool query = false}) {
    return validate(req, query: query).then(f);
  }

  /// Uses the [codec] to [deserialize] the result of calling [validate].
  ///
  /// If [query] is `true` (default: `false`), then the value will
  /// be read from the request `queryParameters` instead.
  Future<T> decode<T>(RequestContext req, Codec<T, Map> codec,
      {bool query = false}) {
    return deserialize(req, codec.decode, query: query);
  }

  /// Calls [read], and returns the filtered request body.
  /// If there is even one error, then an [AngelHttpException] is thrown.
  ///
  /// If [query] is `true` (default: `false`), then the value will
  /// be read from the request `queryParameters` instead.
  Future<Map<String, dynamic>> validate(RequestContext req,
      {bool query = false}) async {
    var result = await read(req, query: query);
    if (!result.isSuccess) {
      throw AngelHttpException.badRequest(
          message: errorMessage, errors: result.errors.toList());
    } else {
      return result.value;
    }
  }

  /// Reads the body of the [RequestContext], and returns an object detailing
  /// whether valid values were provided for all [fields].
  ///
  /// In most cases, you'll want to use [validate] instead.
  ///
  /// If [query] is `true` (default: `false`), then the value will
  /// be read from the request `queryParameters` instead.
  Future<FieldReadResult<Map<String, dynamic>>> read(RequestContext req,
      {bool query = false}) async {
    var out = <String, dynamic>{};
    var errors = <String>[];
    var uploadedFiles = <UploadedFile>[];
    if (req.hasParsedBody || !query) {
      await req.parseBody();
      uploadedFiles = req.uploadedFiles;
    }

    for (var field in fields) {
      var result = await field.read(
          req, query ? req.queryParameters : req.bodyAsMap, uploadedFiles);
      if (result == null && field.isRequired) {
        errors.add(reportMissingField(field.name, query: query));
      } else if (!result.isSuccess) {
        errors.addAll(result.errors);
      } else {
        out[field.name] = result.value;
      }
    }

    if (errors.isNotEmpty) {
      return FieldReadResult.failure(errors);
    } else {
      return FieldReadResult.success(out);
    }
  }
}
