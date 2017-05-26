# paginate
[![version 1.0.0](https://img.shields.io/badge/pub-v1.0.0-brightgreen.svg)](https://pub.dartlang.org/packages/angel_paginate)
[![build status](https://travis-ci.org/angel-dart/paginate.svg)](https://travis-ci.org/angel-dart/paginate)

Platform-agnostic pagination library, with custom support for the
[Angel framework](https://github.com/angel-dart/angel).

# Installation
In your `pubspec.yaml` file:

```yaml
dependencies:
  angel_paginate: ^1.0.0
```

# Usage
This library exports a `Paginator<T>`, which can be used to efficiently produce
instances of `PaginationResult<T>`. Pagination results, when serialized to JSON, look like
this:

```json
{
  "total" : 75,
  "items_per_page" : 10,
  "previous_page" : 3,
  "current_page" : 4,
  "next_page" : 5,
  "start_index" : 30,
  "end_index" : 39,
  "data" : ["<items...>"]
}
```

Results can be parsed from Maps using the `PaginationResult<T>.fromMap` constructor, and
serialized via their `toJson()` method.

To create a paginator:

```dart
import 'package:angel_paginate/angel_paginate.dart';

main() {
  var p = new Paginator(iterable);
  
  // Get the current page (default: page 1)
  var page = p.current;
  print(page.total);
  print(page.startIndex);
  print(page.data); // The actual items on this page.
  p.next(); // Advance a page
  p.goBack(); // Back one page
  p.goToPage(10); // Go to page number (1-based, not a 0-based index)
}
```

The entire Paginator API is documented, so check out the DartDocs.

Paginators by default cache paginations, to improve performance as you shift through pages.
This can be especially helpful in a client-side application where your UX involves a fast
response time, i.e. a search page.

## Use With Angel
Naturally, a library named `angel_paginate` has special provisions for the
[Angel framework](https://github.com/angel-dart/angel).

In `package:angel_paginate/server.dart`, a function called `paginate` generates
pagination service hooks for you. If the result of a hooked service event is an `Iterable`,
it will be paginated. This is convenient because it works with any data store, whether it
be MongoDB, RethinkDB, an in-memory store, or something else entirely.

```dart
configureServer(Angel app) {
  var service = app.service('api/foo') as HookedService;
  service.afterIndexed.listen(paginate(itemsPerPage: 10));
}
```

See `test/server_test.dart` for examples of usage with Angel.