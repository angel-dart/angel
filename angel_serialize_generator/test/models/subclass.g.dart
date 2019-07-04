// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subclass.dart';

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Animal extends _Animal {
  Animal({@required this.genus, @required this.species});

  @override
  String genus;

  @override
  String species;

  Animal copyWith({String genus, String species}) {
    return Animal(genus: genus ?? this.genus, species: species ?? this.species);
  }

  bool operator ==(other) {
    return other is _Animal && other.genus == genus && other.species == species;
  }

  @override
  int get hashCode {
    return hashObjects([genus, species]);
  }

  @override
  String toString() {
    return "Animal(genus=$genus, species=$species)";
  }

  Map<String, dynamic> toJson() {
    return AnimalSerializer.toMap(this);
  }
}

@generatedSerializable
class Bird extends _Bird {
  Bird({@required this.genus, @required this.species, this.isSparrow = false});

  @override
  String genus;

  @override
  String species;

  @override
  bool isSparrow;

  Bird copyWith({String genus, String species, bool isSparrow}) {
    return Bird(
        genus: genus ?? this.genus,
        species: species ?? this.species,
        isSparrow: isSparrow ?? this.isSparrow);
  }

  bool operator ==(other) {
    return other is _Bird &&
        other.genus == genus &&
        other.species == species &&
        other.isSparrow == isSparrow;
  }

  @override
  int get hashCode {
    return hashObjects([genus, species, isSparrow]);
  }

  @override
  String toString() {
    return "Bird(genus=$genus, species=$species, isSparrow=$isSparrow)";
  }

  Map<String, dynamic> toJson() {
    return BirdSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const AnimalSerializer animalSerializer = AnimalSerializer();

class AnimalEncoder extends Converter<Animal, Map> {
  const AnimalEncoder();

  @override
  Map convert(Animal model) => AnimalSerializer.toMap(model);
}

class AnimalDecoder extends Converter<Map, Animal> {
  const AnimalDecoder();

  @override
  Animal convert(Map map) => AnimalSerializer.fromMap(map);
}

class AnimalSerializer extends Codec<Animal, Map> {
  const AnimalSerializer();

  @override
  get encoder => const AnimalEncoder();
  @override
  get decoder => const AnimalDecoder();
  static Animal fromMap(Map map) {
    if (map['genus'] == null) {
      throw FormatException("Missing required field 'genus' on Animal.");
    }

    if (map['species'] == null) {
      throw FormatException("Missing required field 'species' on Animal.");
    }

    return Animal(
        genus: map['genus'] as String, species: map['species'] as String);
  }

  static Map<String, dynamic> toMap(_Animal model) {
    if (model == null) {
      return null;
    }
    if (model.genus == null) {
      throw FormatException("Missing required field 'genus' on Animal.");
    }

    if (model.species == null) {
      throw FormatException("Missing required field 'species' on Animal.");
    }

    return {'genus': model.genus, 'species': model.species};
  }
}

abstract class AnimalFields {
  static const List<String> allFields = <String>[genus, species];

  static const String genus = 'genus';

  static const String species = 'species';
}

const BirdSerializer birdSerializer = BirdSerializer();

class BirdEncoder extends Converter<Bird, Map> {
  const BirdEncoder();

  @override
  Map convert(Bird model) => BirdSerializer.toMap(model);
}

class BirdDecoder extends Converter<Map, Bird> {
  const BirdDecoder();

  @override
  Bird convert(Map map) => BirdSerializer.fromMap(map);
}

class BirdSerializer extends Codec<Bird, Map> {
  const BirdSerializer();

  @override
  get encoder => const BirdEncoder();
  @override
  get decoder => const BirdDecoder();
  static Bird fromMap(Map map) {
    if (map['genus'] == null) {
      throw FormatException("Missing required field 'genus' on Bird.");
    }

    if (map['species'] == null) {
      throw FormatException("Missing required field 'species' on Bird.");
    }

    return Bird(
        genus: map['genus'] as String,
        species: map['species'] as String,
        isSparrow: map['is_sparrow'] as bool ?? false);
  }

  static Map<String, dynamic> toMap(_Bird model) {
    if (model == null) {
      return null;
    }
    if (model.genus == null) {
      throw FormatException("Missing required field 'genus' on Bird.");
    }

    if (model.species == null) {
      throw FormatException("Missing required field 'species' on Bird.");
    }

    return {
      'genus': model.genus,
      'species': model.species,
      'is_sparrow': model.isSparrow
    };
  }
}

abstract class BirdFields {
  static const List<String> allFields = <String>[genus, species, isSparrow];

  static const String genus = 'genus';

  static const String species = 'species';

  static const String isSparrow = 'is_sparrow';
}
