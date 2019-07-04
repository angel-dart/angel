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
    return GamepadButton(
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

  @override
  String toString() {
    return "GamepadButton(name=$name, radius=$radius)";
  }

  Map<String, dynamic> toJson() {
    return GamepadButtonSerializer.toMap(this);
  }
}

@generatedSerializable
class Gamepad extends _Gamepad {
  Gamepad({List<_GamepadButton> buttons, Map<String, dynamic> dynamicMap})
      : this.buttons = List.unmodifiable(buttons ?? []),
        this.dynamicMap = Map.unmodifiable(dynamicMap ?? {});

  @override
  List<_GamepadButton> buttons;

  @override
  Map<String, dynamic> dynamicMap;

  Gamepad copyWith(
      {List<_GamepadButton> buttons, Map<String, dynamic> dynamicMap}) {
    return Gamepad(
        buttons: buttons ?? this.buttons,
        dynamicMap: dynamicMap ?? this.dynamicMap);
  }

  bool operator ==(other) {
    return other is _Gamepad &&
        ListEquality<_GamepadButton>(DefaultEquality<_GamepadButton>())
            .equals(other.buttons, buttons) &&
        MapEquality<String, dynamic>(
                keys: DefaultEquality<String>(), values: DefaultEquality())
            .equals(other.dynamicMap, dynamicMap);
  }

  @override
  int get hashCode {
    return hashObjects([buttons, dynamicMap]);
  }

  @override
  String toString() {
    return "Gamepad(buttons=$buttons, dynamicMap=$dynamicMap)";
  }

  Map<String, dynamic> toJson() {
    return GamepadSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const GamepadButtonSerializer gamepadButtonSerializer =
    GamepadButtonSerializer();

class GamepadButtonEncoder extends Converter<GamepadButton, Map> {
  const GamepadButtonEncoder();

  @override
  Map convert(GamepadButton model) => GamepadButtonSerializer.toMap(model);
}

class GamepadButtonDecoder extends Converter<Map, GamepadButton> {
  const GamepadButtonDecoder();

  @override
  GamepadButton convert(Map map) => GamepadButtonSerializer.fromMap(map);
}

class GamepadButtonSerializer extends Codec<GamepadButton, Map> {
  const GamepadButtonSerializer();

  @override
  get encoder => const GamepadButtonEncoder();
  @override
  get decoder => const GamepadButtonDecoder();
  static GamepadButton fromMap(Map map) {
    return GamepadButton(
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

const GamepadSerializer gamepadSerializer = GamepadSerializer();

class GamepadEncoder extends Converter<Gamepad, Map> {
  const GamepadEncoder();

  @override
  Map convert(Gamepad model) => GamepadSerializer.toMap(model);
}

class GamepadDecoder extends Converter<Map, Gamepad> {
  const GamepadDecoder();

  @override
  Gamepad convert(Map map) => GamepadSerializer.fromMap(map);
}

class GamepadSerializer extends Codec<Gamepad, Map> {
  const GamepadSerializer();

  @override
  get encoder => const GamepadEncoder();
  @override
  get decoder => const GamepadDecoder();
  static Gamepad fromMap(Map map) {
    return Gamepad(
        buttons: map['buttons'] is Iterable
            ? List.unmodifiable(((map['buttons'] as Iterable).whereType<Map>())
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
