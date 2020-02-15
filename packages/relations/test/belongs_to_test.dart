import 'package:angel_framework/angel_framework.dart';
import 'package:angel_relations/angel_relations.dart' as relations;
import 'package:angel_seeder/angel_seeder.dart';
import 'package:test/test.dart';
import 'common.dart';

main() {
  Angel app;

  setUp(() async {
    app = new Angel()
      ..use('/authors', new MapService())
      ..use('/books', new MapService());

    await app.configure(seed(
        'authors',
        new SeederConfiguration<Map>(
            count: 10,
            template: {'name': (Faker faker) => faker.person.name()},
            callback: (Map author, seed) {
              return seed(
                  'books',
                  new SeederConfiguration(delete: false, count: 10, template: {
                    'authorId': author['id'],
                    'title': (Faker faker) =>
                        'I love to eat ${faker.food.dish()}'
                  }));
            })));

    app.service('books').afterAll(relations.belongsTo('authors'));
  });

  test('index', () async {
    var books = await app.service('books').index();
    print(books);

    expect(books, allOf(isList, isNotEmpty));

    for (Map book in books) {
      expect(book.keys, contains('author'));

      Map author = book['author'];
      expect(author['id'], equals(book['authorId']));
    }
  });

  test('create', () async {
    var warAndPeace = await app
        .service('books')
        .create(new Book(title: 'War and Peace').toJson());

    print(warAndPeace);
    expect(warAndPeace.keys, contains('author'));
    expect(warAndPeace['author'], isNull);
  });
}
