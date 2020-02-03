import 'package:angel_framework/angel_framework.dart';
import 'package:graphql_schema/graphql_schema.dart';
export 'src/graphiql.dart';
export 'src/graphql_http.dart';
export 'src/graphql_ws.dart';
export 'src/resolvers.dart';

/// The canonical [GraphQLUploadType] instance.
final GraphQLUploadType graphQLUpload = GraphQLUploadType();

/// A [GraphQLScalarType] that is used to read uploaded files from
/// `multipart/form-data` requests.
class GraphQLUploadType extends GraphQLScalarType<UploadedFile, UploadedFile> {
  @override
  String get name => 'Upload';

  @override
  String get description =>
      'Represents a file that has been uploaded to the server.';

  @override
  GraphQLType<UploadedFile, UploadedFile> coerceToInputObject() => this;

  @override
  UploadedFile deserialize(UploadedFile serialized) => serialized;

  @override
  UploadedFile serialize(UploadedFile value) => value;

  @override
  ValidationResult<UploadedFile> validate(String key, UploadedFile input) {
    if (input != null && input is! UploadedFile) {
      return _Vr(false, errors: ['Expected "$key" to be a boolean.']);
    }
    return _Vr(true, value: input);
  }
}

// TODO: Really need to make the validation result constructors *public*
class _Vr<T> implements ValidationResult<T> {
  final bool successful;
  final List<String> errors;
  final T value;

  _Vr(this.successful, {this.errors, this.value});
}
