// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_pad_button.dart';

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class GamepadButton implements _GamepadButton {
  const GamepadButton({this.name, this.radius});

  @override
  final String name;

  @override
  final int radius;

  GamepadButton copyWith({String name, int radius}) {
    return new GamepadButton(
        name: name ?? this.name, radius: radius ?? this.radius);
  }

  bool operator ==(other) {
    return other is _GamepadButton &&
        other.name == name &&
        other.radius == radius;
  }

  @override
  int get hashCode {
    return hashObjects([name, radius]);
  }

  Map<String, dynamic> toJson() {
    return GamepadButtonSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class GamepadButtonSerializer {
  static GamepadButton fromMap(Map map) {
    return new GamepadButton(
        name: map['name'] as String, radius: map['radius'] as int);
  }

  static Map<String, dynamic> toMap(_GamepadButton model) {
    if (model == null) {
      return null;
    }
    return {'name': model.name, 'radius': model.radius};
  }
}

abstract class GamepadButtonFields {
  static const List<String> allFields = const <String>[name, radius];

  static const String name = 'name';

  static const String radius = 'radius';
}
