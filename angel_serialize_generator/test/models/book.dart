library angel_serialize.test.models.book;

import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:collection/collection.dart';
part 'book.g.dart';

@Serializable(
  serializers: Serializers.all,
  includeAnnotations: [
    pragma('hello'),
    SerializableField(alias: 'omg'),
  ],
)
abstract class _Book extends Model {
  String author, title, description;
  int pageCount;
  List<double> notModels;

  @SerializableField(alias: 'camelCase', isNullable: true)
  String camelCaseString;
}
