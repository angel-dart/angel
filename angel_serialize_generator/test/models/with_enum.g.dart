// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'with_enum.dart';

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class WithEnum implements _WithEnum {
  const WithEnum({this.type, List<int> this.finalList, this.imageBytes});

  @override
  final WithEnumType type;

  @override
  final List<int> finalList;

  @override
  final Uint8List imageBytes;

  WithEnum copyWith(
      {WithEnumType type, List<int> finalList, Uint8List imageBytes}) {
    return new WithEnum(
        type: type ?? this.type,
        finalList: finalList ?? this.finalList,
        imageBytes: imageBytes ?? this.imageBytes);
  }

  bool operator ==(other) {
    return other is _WithEnum &&
        other.type == type &&
        const ListEquality<int>(const DefaultEquality<int>())
            .equals(other.finalList, finalList) &&
        const ListEquality().equals(other.imageBytes, imageBytes);
  }

  @override
  int get hashCode {
    return hashObjects([type, finalList, imageBytes]);
  }

  Map<String, dynamic> toJson() {
    return WithEnumSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class WithEnumSerializer {
  static WithEnum fromMap(Map map) {
    return new WithEnum(
        type: map['type'] is WithEnumType
            ? (map['type'] as WithEnumType)
            : (map['type'] is int
                ? WithEnumType.values[map['type'] as int]
                : null),
        finalList: map['final_list'] is Iterable
            ? (map['final_list'] as Iterable).cast<int>().toList()
            : null,
        imageBytes: map['image_bytes'] is Uint8List
            ? (map['image_bytes'] as Uint8List)
            : (map['image_bytes'] is Iterable<int>
                ? new Uint8List.fromList(
                    (map['image_bytes'] as Iterable<int>).toList())
                : (map['image_bytes'] is String
                    ? new Uint8List.fromList(
                        base64.decode(map['image_bytes'] as String))
                    : null)));
  }

  static Map<String, dynamic> toMap(_WithEnum model) {
    if (model == null) {
      return null;
    }
    return {
      'type':
          model.type == null ? null : WithEnumType.values.indexOf(model.type),
      'final_list': model.finalList,
      'image_bytes':
          model.imageBytes == null ? null : base64.encode(model.imageBytes)
    };
  }
}

abstract class WithEnumFields {
  static const List<String> allFields = const <String>[
    type,
    finalList,
    imageBytes
  ];

  static const String type = 'type';

  static const String finalList = 'final_list';

  static const String imageBytes = 'image_bytes';
}
