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

  Map<String, dynamic> toJson() {
    return GamepadButtonSerializer.toMap(this);
  }
}
