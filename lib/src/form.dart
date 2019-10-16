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
/// import 'package:angel_forms/angel_forms.dart';
/// import 'package:angel_validate/angel_validate.dart';
///
/// var myForm = Form(fields: [
///   TextField('username').match([]),
///   TextField('password', confirmedAs: 'confirm_password'),
/// ])
///
/// app.post('/login', (req, res) async {
///   var loginRequest =
///     await myForm.decode(req, loginRequestSerializer);
///   // Do something with the decode object...
/// });
/// ```
class Form {
  final String errorMessage;

  final List<Field> _fields = [];
  final List<String> _errors = [];

  static const String defaultErrorMessage =
      'There were errors in your submission. '
      'Please make sure all fields entered correctly, and submit it again.';

  Form({this.errorMessage = defaultErrorMessage, Iterable<Field> fields}) {
    fields?.forEach(addField);
  }

  List<Field> get fields => _fields;

  List<String> get errors => _errors;

  Field<T> addField<T>(Field<T> field, {Iterable<Matcher> matchers}) {
    if (matchers != null) {
      field = field.match(matchers);
    }
    _fields.add(field);
    return field;
  }

  Future<T> deserialize<T>(
      RequestContext req, T Function(Map<String, dynamic>) f) {
    return validate(req).then(f);
  }

  Future<T> decode<T>(RequestContext req, Codec<T, Map> codec) {
    return deserialize(req, codec.decode);
  }

  Future<Map<String, dynamic>> validate(RequestContext req) async {
    var result = await read(req);
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
  Future<FieldReadResult<Map<String, dynamic>>> read(RequestContext req) async {
    var out = <String, dynamic>{};
    var errors = <String>[];
    await req.parseBody();

    for (var field in fields) {
      var result = await field.read(req);
      if (result == null && field.isRequired) {
        errors.add('The field "${field.name}" is required.');
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
