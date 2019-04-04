// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_pad.dart';

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Gamepad extends _Gamepad {
  Gamepad(
      {@required List<dynamic> buttons,
      @required Map<String, dynamic> dynamicMap})
      : this.buttons = new List.unmodifiable(buttons ?? []),
        this.dynamicMap = new Map.unmodifiable(dynamicMap ?? {});

  @override
  final List<dynamic> buttons;

  @override
  final Map<String, dynamic> dynamicMap;

  Gamepad copyWith({List<dynamic> buttons, Map<String, dynamic> dynamicMap}) {
    return new Gamepad(
        buttons: buttons ?? this.buttons,
        dynamicMap: dynamicMap ?? this.dynamicMap);
  }

  bool operator ==(other) {
    return other is _Gamepad &&
        const ListEquality<dynamic>(const DefaultEquality())
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
    if (map['buttons'] == null) {
      throw new FormatException("Missing required field 'buttons' on Gamepad.");
    }

    if (map['dynamic_map'] == null) {
      throw new FormatException(
          "Missing required field 'dynamic_map' on Gamepad.");
    }

    return new Gamepad(
        buttons: map['buttons'] is Iterable
            ? (map['buttons'] as Iterable).cast<dynamic>().toList()
            : null,
        dynamicMap: map['dynamic_map'] is Map
            ? (map['dynamic_map'] as Map).cast<String, dynamic>()
            : null);
  }

  static Map<String, dynamic> toMap(_Gamepad model) {
    if (model == null) {
      return null;
    }
    if (model.buttons == null) {
      throw new FormatException("Missing required field 'buttons' on Gamepad.");
    }

    if (model.dynamicMap == null) {
      throw new FormatException(
          "Missing required field 'dynamic_map' on Gamepad.");
    }

    return {'buttons': model.buttons, 'dynamic_map': model.dynamicMap};
  }
}

abstract class GamepadFields {
  static const List<String> allFields = <String>[buttons, dynamicMap];

  static const String buttons = 'buttons';

  static const String dynamicMap = 'dynamic_map';
}
