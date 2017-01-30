String singular(String path) {
  var str = path.trim().split('/').where((str) => str.isNotEmpty).last;

  if (str.endsWith('ies'))
    return str.substring(0, str.length - 3) + 'y';
  else if (str.endsWith('s'))
    return str.substring(0, str.length - 1);
  else
    return str;
}

String plural(String path) {
  var str = path.trim().split('/').where((str) => str.isNotEmpty).last;

  if (str.endsWith('y'))
    return str.substring(0, str.length - 1) + 'ies';
  else if (str.endsWith('s'))
    return str;
  else
    return str + 's';
}
