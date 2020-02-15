import 'dart:async';
import 'common_fields.dart';
import 'field.dart';

abstract class FormRenderer<T> {
  const FormRenderer();

  FutureOr<T> visit(Field<T> field) => field.accept(this);

  FutureOr<T> visitBoolField(BoolField field);

  FutureOr<T> visitDateTimeField(DateTimeField field);

  FutureOr<T> visitFileField(FileField field);

  FutureOr<T> visitImageField(ImageField field);

  FutureOr<T> visitNumField(NumField field);

  FutureOr<T> visitTextField(TextField field);
}
