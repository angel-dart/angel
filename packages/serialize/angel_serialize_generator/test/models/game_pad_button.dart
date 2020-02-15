import 'package:angel_serialize/angel_serialize.dart';
part 'game_pad_button.g.dart';

@serializable
abstract class _GamepadButton {
  String get name;
  int get radius;
}

@serializable
class _Gamepad {
  List<_GamepadButton> buttons;

  Map<String, dynamic> dynamicMap;

  // ignore: unused_field
  String _somethingPrivate;
}
