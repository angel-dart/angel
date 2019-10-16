import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:matcher/matcher.dart';
import 'form_renderer.dart';

class FieldReadResult<T> {
  final bool isSuccess;
  final T value;
  final Iterable<String> errors;

  FieldReadResult.success(this.value)
      : isSuccess = true,
        errors = null;

  FieldReadResult.failure(this.errors)
      : isSuccess = false,
        value = null;
}

abstract class Field<T> {
  final String name;
  final String label;
  final bool isRequired;

  Field(this.name, {this.label, this.isRequired = false});

  FutureOr<FieldReadResult<T>> read(RequestContext req);

  FutureOr<U> accept<U>(FormRenderer<U> renderer);

  Field<T> match(Iterable<Matcher> matchers) => _MatchedField(this, matchers);
}

class _MatchedField<T> extends Field<T> {
  final Field<T> inner;
  final Iterable<Matcher> matchers;

  _MatchedField(this.inner, this.matchers)
      : super(inner.name, label: inner.label, isRequired: inner.isRequired) {
    assert(matchers.isNotEmpty);
  }

  @override
  FutureOr<U> accept<U>(FormRenderer<U> renderer) => inner.accept(renderer);

  @override
  Future<FieldReadResult<T>> read(RequestContext req) async {
    var result = await inner.read(req);
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
