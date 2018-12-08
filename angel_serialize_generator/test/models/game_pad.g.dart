// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_pad.dart';

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Gamepad extends _Gamepad {
  Gamepad({List<GamepadButton> buttons, Map<String, dynamic> dynamicMap})
      : this.buttons = new List.unmodifiable(buttons ?? []),
        this.dynamicMap = new Map.unmodifiable(dynamicMap ?? {});

  @override
  final List<GamepadButton> buttons;

  @override
  final Map<String, dynamic> dynamicMap;

  Gamepad copyWith(
      {List<GamepadButton> buttons, Map<String, dynamic> dynamicMap}) {
    return new Gamepad(
        buttons: buttons ?? this.buttons,
        dynamicMap: dynamicMap ?? this.dynamicMap);
  }

  bool operator ==(other) {
    return other is _Gamepad &&
        const ListEquality<GamepadButton>(
                const DefaultEquality<GamepadButton>())
            .equals(other.buttons, buttons) &&
        const MapEquality<String, dynamic>(
                keys: const DefaultEquality<String>(),
                values: const DefaultEquality())
            .equals(other.dynamicMap, dynamicMap);
  }

  @override
  int get hashCode {
    return hashObjects([buttons, dynamicMap]);
  }

  Map<String, dynamic> toJson() {
    return GamepadSerializer.toMap(this);
  }
}

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
        dynamicMap: map['dynamic_map'] is Map
            ? (map['dynamic_map'] as Map).cast<String, dynamic>()
            : null);
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
  static const List<String> allFields = const <String>[buttons, dynamicMap];

  static const String buttons = 'buttons';

  static const String dynamicMap = 'dynamic_map';
}
