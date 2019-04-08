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

@generatedSerializable
class Gamepad extends _Gamepad {
  Gamepad({List<_GamepadButton> buttons, Map<String, dynamic> dynamicMap})
      : this.buttons = new List.unmodifiable(buttons ?? []),
        this.dynamicMap = new Map.unmodifiable(dynamicMap ?? {});

  @override
  final List<_GamepadButton> buttons;

  @override
  final Map<String, dynamic> dynamicMap;

  Gamepad copyWith(
      {List<_GamepadButton> buttons, Map<String, dynamic> dynamicMap}) {
    return new Gamepad(
        buttons: buttons ?? this.buttons,
        dynamicMap: dynamicMap ?? this.dynamicMap);
  }

  bool operator ==(other) {
    return other is _Gamepad &&
        const ListEquality<_GamepadButton>(
                const DefaultEquality<_GamepadButton>())
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
  static const List<String> allFields = <String>[name, radius];

  static const String name = 'name';

  static const String radius = 'radius';
}

abstract class GamepadSerializer {
  static Gamepad fromMap(Map map) {
    return new Gamepad(
        buttons: map['buttons'] is Iterable
            ? new List.unmodifiable(
                ((map['buttons'] as Iterable).where((x) => x is Map))
                    .cast<Map>()
                    .map(GamepadButtonSerializer.fromMap))
            : null,
        dynamicMap: map['dynamic_map'] is Map
            ? (map['dynamic_map'] as Map).cast<String, dynamic>()
            : null);
  }

  static Map<String, dynamic> toMap(_Gamepad model) {
    if (model == null) {
      return null;
    }
    return {
      'buttons':
          model.buttons?.map((m) => GamepadButtonSerializer.toMap(m))?.toList(),
      'dynamic_map': model.dynamicMap
    };
  }
}

abstract class GamepadFields {
  static const List<String> allFields = <String>[buttons, dynamicMap];

  static const String buttons = 'buttons';

  static const String dynamicMap = 'dynamic_map';
}
