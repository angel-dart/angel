import "package:angel_framework/common.dart";

class Postcard extends Model {
  String location;
  String message;

  Postcard({String id, this.location, this.message}) {
    this.id = id;
  }

  factory Postcard.fromJson(Map data) => new Postcard(
      id: data['id'], location: data['location'], message: data['message']);

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
