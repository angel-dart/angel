import 'query.dart';

abstract class QueryValues {
  Map<String, String> get casts => {};

  Map<String, dynamic> toMap();

  String applyCast(String name, String sub) {
    if (casts.containsKey(name)) {
      var type = casts[name];
      return 'CAST ($sub as $type)';
    } else {
      return sub;
    }
  }

  String compileInsert(Query query, String tableName) {
    var data = Map<String, dynamic>.from(toMap());
    var keys = data.keys.toList();
    keys.where((k) => !query.fields.contains(k)).forEach(data.remove);
    if (data.isEmpty) return null;

    var fieldSet = data.keys.join(', ');
    var b = StringBuffer('INSERT INTO $tableName ($fieldSet) VALUES (');
    int i = 0;

    for (var entry in data.entries) {
      if (i++ > 0) b.write(', ');

      var name = query.reserveName(entry.key);
      var s = applyCast(entry.key, '@$name');
      query.substitutionValues[name] = entry.value;
      b.write(s);
    }

    b.write(')');
    return b.toString();
  }

  String compileForUpdate(Query query) {
    var data = toMap();
    if (data.isEmpty) return null;
    var b = StringBuffer('SET');
    int i = 0;

    for (var entry in data.entries) {
      if (i++ > 0) b.write(',');
      b.write(' ');
      b.write(entry.key);
      b.write('=');

      var name = query.reserveName(entry.key);
      var s = applyCast(entry.key, '@$name');
      query.substitutionValues[name] = entry.value;
      b.write(s);
    }
    return b.toString();
  }
}
