// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'with_enum.dart';

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

class WithEnum implements _WithEnum {
  const WithEnum({this.type});

  @override
  final WithEnumType type;

  WithEnum copyWith({WithEnumType type}) {
    return new WithEnum(type: type ?? this.type);
  }

  bool operator ==(other) {
    return other is _WithEnum && other.type == type;
  }

  Map<String, dynamic> toJson() {
    return WithEnumSerializer.toMap(this);
  }
}
