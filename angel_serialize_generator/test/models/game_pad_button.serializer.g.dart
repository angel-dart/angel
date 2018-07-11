// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_pad_button.dart';

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class GamepadButtonSerializer {
  static GamepadButton fromMap(Map map) {
    return new GamepadButton(
        name: map['name'] as String, radius: map['radius'] as int);
  }

  static Map<String, dynamic> toMap(GamepadButton model) {
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
