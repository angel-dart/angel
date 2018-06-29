// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'with_enum.dart';

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class WithEnumSerializer {
  static WithEnum fromMap(Map map) {
    return new WithEnum(
        type: map['type'] is WithEnumType
            ? map['type']
            : (map['type'] is int ? WithEnumType.values[map['type']] : null),
        finalList: map['final_list'] as List<int>);
  }

  static Map<String, dynamic> toMap(WithEnum model) {
    if (model == null) {
      return null;
    }
    return {
      'type':
          model.type == null ? null : WithEnumType.values.indexOf(model.type),
      'final_list': model.finalList
    };
  }
}

abstract class WithEnumFields {
  static const String type = 'type';

  static const String finalList = 'final_list';
}
