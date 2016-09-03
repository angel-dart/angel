import "package:angel_framework/defs.dart";

class Postcard extends MemoryModel {
  int id;
  String location;
  String message;

  Postcard({String this.location, String this.message});

  @override
  bool operator ==(other) {
    if (!(other is Postcard))
      return false;

    return id == other.id && location == other.location &&
        message == other.message;
  }


}