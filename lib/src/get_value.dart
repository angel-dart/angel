import 'dart:convert';

getValue(String value) {
  num numValue = num.parse(value, (_) => double.NAN);
  if (!numValue.isNaN)
    return numValue;
  else if (value.startsWith('[') && value.endsWith(']'))
    return JSON.decode(value);
  else if (value.startsWith('{') && value.endsWith('}'))
    return JSON.decode(value);
  else if (value.trim().toLowerCase() == 'null')
    return null;
  else return value;
}