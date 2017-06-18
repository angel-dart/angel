// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_test.test.models.tire;

// **************************************************************************
// Generator: JsonModelGenerator
// Target: class _Tire
// **************************************************************************

class Tire extends _Tire {
  @override
  int size;

  Tire({this.size});

  factory Tire.fromJson(Map data) {
    return new Tire(size: data['size']);
  }

  Map<String, dynamic> toJson() => {'size': size};

  static Tire parse(Map map) => new Tire.fromJson(map);
}
