// Grinder is not part of Angel, but you may consider using it
// to run tasks, a la Gulp.
//
// See its documentation here:
// https://github.com/google/grinder.dart

import 'package:grinder/grinder.dart';

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