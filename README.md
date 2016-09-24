# Body Parser
![version 1.0.0-dev+1](https://img.shields.io/badge/version-1.0.0--dev-red.svg)

**NOT YET PRODUCTION READY**

Parse request bodies and query strings in Dart, as well multipart/form-data uploads. No external
dependencies required.

### Contents

*   [Body Parser](#body-parser)
*   [About](#about)
*   [Installation](#installation)
*   [Usage](#usage)
*   [Thanks](#thank-you-for-using-body-parser)

# About

I needed something like Express.js's `body-parser` module, so I made it here. It fully supports JSON requests.
x-www-form-urlencoded fully supported, as well as query strings. You can also include arrays in your query,
in the same way you would for a PHP application. Full file upload support will also be present by the production 1.0.0 release.

A benefit of this is that primitive types are automatically deserialized correctly. As in, if you have a `hello=1.5` request, then
`body['hello']` will equal `1.5` and not `'1.5'`. A very semantic difference, yes, but it relieves stress in my head.

# Installation

To install Body Parser for your Dart project, simply add body_parser to your
pub dependencies.

    dependencies:
        body_parser: any

# Usage

Body Parser exposes a simple class called [BodyParseResult].
You can easily parse the query string and request body for a request by calling `Future<BodyParseResult> parseBody`.

```dart
import 'dart:convert';
import 'package:body_parser/body_parser.dart';

main() async {
    // ...
    await for (HttpRequest request in server) {
      request.response.write(JSON.encode(await parseBody(request).body));
      await request.response.close();
    }
}
```

You can also use `buildMapFromUri(Map, String)` to populate a map from a URL encoded string.

This can easily be used with a library like [JSON God](https://github.com/thosakwe/json_god)
to build structured JSON/REST APIs. Add validation and you've got an instant backend.

```dart
MyClass create(HttpRequest request) async {
    God god = new God();
    return god.deserialize(await parseBody(request).body, MyClass);
}
```


# Thank you for using Body Parser

Thank you for using this library. I hope you like it.

Feel free to follow me on Twitter:

[@_wapaa_](http://twitter.com/_wapaa_)