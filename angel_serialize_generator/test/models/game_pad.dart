import 'package:angel_serialize/angel_serialize.dart';
import 'package:collection/collection.dart';
import 'game_pad_button.dart';

part 'game_pad.g.dart';

part 'game_pad.serializer.g.dart';

@Serializable(autoIdAndDateFields: false)
class _Gamepad {
  List<GamepadButton> buttons;

  Map<String, dynamic> dynamicMap;

  String _somethingPrivate;
}
