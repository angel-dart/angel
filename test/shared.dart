import "package:angel_framework/src/defs.dart";

class Postcard extends MemoryModel {
  int id;
  String location;
  String message;

  Postcard({String this.location, String this.message});

  @override
  bool operator ==(other) {
    if (!(other is Postcard)) return false;

    return id == other.id &&
        location == other.location &&
        message == other.message;
  }

  Map toJson() {
    return {'id': id, 'location': location, 'message': message};
  }
}
