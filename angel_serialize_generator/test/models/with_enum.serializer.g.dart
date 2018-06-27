// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'with_enum.dart';

// **************************************************************************
// Generator: SerializerGenerator
// **************************************************************************

abstract class WithEnumSerializer {
  static WithEnum fromMap(Map map) {
    return new WithEnum(
        type: map['type'] is WithEnumType
            ? map['type']
            : (map['type'] is int ? WithEnumType.values[map['type']] : null));
  }

  static Map<String, dynamic> toMap(WithEnum model) {
    return {
      'type':
          model.type == null ? null : WithEnumType.values.indexOf(model.type)
    };
  }
}

abstract class WithEnumFields {
  static const String type = 'type';
}
