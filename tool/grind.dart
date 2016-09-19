import 'dart:async';
import 'dart:io';
import 'package:angel/migrations/migrations.dart';
import 'package:furlong/furlong.dart';
import 'package:grinder/grinder.dart';

final List<Migration> migrations = [
  // Your migrations here!
  new GroupMigration(),
  new TodoMigration()
];

main(args) => grind(args);

@Task()
test() => new TestRunner().testAsync();

@DefaultTask()
@Depends(test)
build() {
  Pub.build();
}

@Task()
clean() => defaultClean();

@Task("Generates classes from your Furlong migrations.")
generate() async {}

@Task("Reverts the database state to before any Furlong migrations were run.")
down() => migrateDown(migrations);

@Task("Undoes and re-runs all Furlong migrations.")
reset() => migrateReset(migrations);

@Task("Undoes the last batch of Furlong migrations run.")
revert() => migrateRevert(migrations);

@Task("Runs any outstanding Furlong migrations.")
up() => migrateUp(migrations);
