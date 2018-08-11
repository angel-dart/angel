import 'package:dart2_constant/convert.dart';

getValue(String value) {
  try {
    num numValue = num.parse(value);
    if (!numValue.isNaN)
      return numValue;
    else
      return value;
  } on FormatException {
    if (value.startsWith('[') && value.endsWith(']'))
      return json.decode(value);
    else if (value.startsWith('{') && value.endsWith('}'))
      return json.decode(value);
    else if (value.trim().toLowerCase() == 'null')
      return null;
    else
      return value;
  }
}
