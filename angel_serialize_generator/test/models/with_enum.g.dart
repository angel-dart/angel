// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'with_enum.dart';

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class WithEnum implements _WithEnum {
  const WithEnum({this.type, List<int> this.finalList});

  @override
  final WithEnumType type;

  @override
  final List<int> finalList;

  WithEnum copyWith({WithEnumType type, List<int> finalList}) {
    return new WithEnum(
        type: type ?? this.type, finalList: finalList ?? this.finalList);
  }

  bool operator ==(other) {
    return other is _WithEnum &&
        other.type == type &&
        const ListEquality<int>(const DefaultEquality<int>())
            .equals(other.finalList, finalList);
  }

  Map<String, dynamic> toJson() {
    return WithEnumSerializer.toMap(this);
  }
}
