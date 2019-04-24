import 'package:graphql_schema/graphql_schema.dart';
import 'package:graphql_server/mirrors.dart';
import 'package:test/test.dart';

void main() {
  group('convertDartType', () {
    group('on enum', () {
      // ignore: deprecated_member_use_from_same_package
      var type = convertDartType(RomanceLanguage);
      var asEnumType = type as GraphQLEnumType;

      test('produces enum type', () {
        expect(type is GraphQLEnumType, true);
      });

      test('rejects invalid value', () {
        expect(asEnumType.validate('@root', 'GERMAN').successful, false);
      });

      test('accepts valid value', () {
        expect(asEnumType.validate('@root', 'SPANISH').successful, true);
      });

      test('deserializes to concrete value', () {
        expect(asEnumType.deserialize('ITALIAN'), RomanceLanguage.ITALIAN);
      });

      test('serializes to concrete value', () {
        expect(asEnumType.serialize(RomanceLanguage.FRANCE), 'FRANCE');
      });

      test('can serialize null', () {
        expect(asEnumType.serialize(null), null);
      });

      test('fails to serialize invalid value', () {
        expect(() => asEnumType.serialize(34), throwsStateError);
      });

      test('fails to deserialize invalid value', () {
        expect(() => asEnumType.deserialize('JAPANESE'), throwsStateError);
      });
    });
  });
}

@graphQLClass
enum RomanceLanguage {
  SPANISH,
  FRANCE,
  ITALIAN,
}
