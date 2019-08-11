import 'package:angel_validate/angel_validate.dart';

main() {
  var bio = new Validator({
    'age*': [isInt, greaterThanOrEqualTo(0)],
    'birthYear*': isInt,
    'countryOfOrigin': isString
  });

  var book = new Validator({
    'title*': isString,
    'year*': [
      isNum,
      (year) {
        return year <= new DateTime.now().year;
      }
    ]
  });

  // ignore: unused_local_variable
  var author = new Validator({
    'bio*': bio,
    'books*': [isList, everyElement(book)]
  }, defaultValues: {
    'books': []
  });
}
