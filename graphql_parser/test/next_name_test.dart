import 'package:test/test.dart';
import 'common.dart';

var githubSrc = r'''
query searchRepos($queryString: String!, $repositoryOrder: RepositoryOrder, $first: Int!) {
  search(type: REPOSITORY, query: $queryString, first: $first) {
    ...SearchResultItemConnection
  }
}
''';

void main() {
  test('can parse formerly-reserved words', () {
    var def = parse(githubSrc).parseOperationDefinition();
    expect(def.isQuery, isTrue);
    print(def.variableDefinitions);
  });
}
