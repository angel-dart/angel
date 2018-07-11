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

  Map<String, dynamic> toJson() {
    return GamepadSerializer.toMap(this);
  }
}
