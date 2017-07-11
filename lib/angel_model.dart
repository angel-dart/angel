/// Represents arbitrary data, with an associated ID and timestamps.
class Model {
  String id;
  DateTime createdAt;
  DateTime updatedAt;

  Model({this.id, this.createdAt, this.updatedAt});
}