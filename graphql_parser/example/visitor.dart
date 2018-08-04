import 'package:graphql_parser/graphql_parser.dart';
import 'package:graphql_parser/visitor.dart';

const String QUERY = '''
{
  foo,
  baz: bar
}
''';

const Map<String, dynamic> DATA = const {
  'foo': 'hello',
  'bar': 'world',
  'quux': 'extraneous'
};

main() {
  // Highly-simplified querying example...
  var result = new MapQuerier(DATA).execute(QUERY);
  print(result); // { foo: hello, baz: world }
  print(result['foo']); // hello
  print(result['baz']); // world
}

class MapQuerier extends GraphQLVisitor {
  final Map<String, dynamic> data;
  final Map<String, dynamic> result = {};

  MapQuerier(this.data);

  Map<String, dynamic> execute(String query) {
    var doc = new Parser(scan(query)).parseDocument();
    visitDocument(doc);
    return result;
  }

  @override
  visitField(FieldContext ctx) {
    String realName, alias;
    if (ctx.fieldName.alias == null)
      realName = alias = ctx.fieldName.name;
    else {
      realName = ctx.fieldName.alias.name;
      alias = ctx.fieldName.alias.alias;
    }

    // Set output field...
    result[alias] = data[realName];
  }
}
