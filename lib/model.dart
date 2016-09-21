library angel_mongo.model;

/// A data type that can be serialized to MongoDB.
class Model {
  /// This instance's ID.
  String id;

  /// The time at which this instance was created.
  DateTime createdAt;

  /// The time at which this instance was last updated.
  DateTime updatedAt;
}