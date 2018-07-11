import 'package:angel_serialize/angel_serialize.dart';
part 'game_pad_button.g.dart';
part 'game_pad_button.serializer.g.dart';

@Serializable(autoIdAndDateFields: false)
abstract class _GamepadButton {
  String get name;
  int get radius;
}
