// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_pad.dart';

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class GamepadSerializer {
  static Gamepad fromMap(Map map) {
    return new Gamepad(
        buttons: map['buttons'] is Iterable
            ? new List.unmodifiable(((map['buttons'] as Iterable)
                    .where((x) => x is Map) as Iterable<Map>)
                .map(GamepadButtonSerializer.fromMap))
            : null,
        dynamicMap: map['dynamic_map'] as Map<String, dynamic>);
  }

  static Map<String, dynamic> toMap(Gamepad model) {
    if (model == null) {
      return null;
    }
    return {
      'buttons': model.buttons?.map((m) => m.toJson())?.toList(),
      'dynamic_map': model.dynamicMap
    };
  }
}

abstract class GamepadFields {
  static const String buttons = 'buttons';

  static const String dynamicMap = 'dynamic_map';
}
