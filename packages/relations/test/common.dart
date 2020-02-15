import 'package:angel_framework/angel_framework.dart';
import 'package:json_god/json_god.dart' as god;

@deprecated
class CustomMapService extends Service {
  final List<Map> _items = [];

  Iterable<Map> tailor(Iterable<Map> items, Map params) {
    if (params == null) return items;

    var r = items;

    if (params != null && params['query'] is Map) {
      Map query = params['query'];

      for (var key in query.keys) {
        r = r.where((m) => m[key] == query[key]);
      }
    }

    return r;
  }

  @override
  index([params]) async => tailor(_items, params).toList();

  @override
  read(id, [Map params]) async {
    return tailor(_items, params).firstWhere((m) => m['id'] == id,
        orElse: () => throw new AngelHttpException.notFound());
  }

  @override
  create(data, [params]) async {
    Map d = data is Map ? data : god.serializeObject(data);
    d['id'] = _items.length.toString();
    _items.add(d);
    return d;
  }

  @override
  remove(id, [params]) async {
    if (id == null) _items.clear();
  }
}

class Author {
  String id, name;

  Author({this.id, this.name});

  Map toJson() => {'id': id, 'name': name};
}

class Book {
  String authorId, title;

  Book({this.authorId, this.title});

  Map toJson() => {'authorId': authorId, 'title': title};
}

class Chapter {
  String bookId, title;
  int pageCount;

  Chapter({this.bookId, this.title, this.pageCount});
}
