import 'package:angel_paginate/angel_paginate.dart';

main() {
  var iterable = [1, 2, 3, 4];
  var p = new Paginator(iterable);

  // Get the current page (default: page 1)
  var page = p.current;
  print(page.total);
  print(page.startIndex);
  print(page.data); // The actual items on this page.
  p.next(); // Advance a page
  p.back(); // Back one page
  p.goToPage(10); // Go to page number (1-based, not a 0-based index)
}
