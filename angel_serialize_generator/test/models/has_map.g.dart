// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'has_map.dart';

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class HasMap implements _HasMap {
  const HasMap({@required Map<dynamic, dynamic> this.value});

  @override
  final Map<dynamic, dynamic> value;

  HasMap copyWith({Map<dynamic, dynamic> value}) {
    return new HasMap(value: value ?? this.value);
  }

  bool operator ==(other) {
    return other is _HasMap &&
        const MapEquality<dynamic, dynamic>(
                keys: const DefaultEquality(), values: const DefaultEquality())
            .equals(other.value, value);
  }

  @override
  int get hashCode {
    return hashObjects([value]);
  }

  Map<String, dynamic> toJson() {
    return HasMapSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class HasMapSerializer {
  static HasMap fromMap(Map map) {
    if (map['value'] == null) {
      throw new FormatException("Missing required field 'value' on HasMap.");
    }

    return new HasMap(value: _fromString(map['value']));
  }

  static Map<String, dynamic> toMap(_HasMap model) {
    if (model == null) {
      return null;
    }
    if (model.value == null) {
      throw new FormatException("Missing required field 'value' on HasMap.");
    }

    return {'value': _toString(model.value)};
  }
}

abstract class HasMapFields {
  static const List<String> allFields = <String>[value];

  static const String value = 'value';
}
