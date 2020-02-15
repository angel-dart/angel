import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mongo/angel_mongo.dart';
import 'package:mongo_dart/mongo_dart.dart';

main() async {
  var app = new Angel();
  Db db = new Db('mongodb://localhost:27017/local');
  await db.open();

  var service = app.use('/api/users', new MongoService(db.collection("users")));

  service.afterCreated.listen((event) {
    print("New user: ${event.result}");
  });
}
