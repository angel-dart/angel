# body_parser
[![Pub](https://img.shields.io/pub/v/body_parser.svg)](https://pub.dartlang.org/packages/body_parser)
[![build status](https://travis-ci.org/angel-dart/body_parser.svg)](https://travis-ci.org/angel-dart/body_parser)

Parse request bodies and query strings in Dart, as well multipart/form-data uploads. No external
dependencies required.

This is the request body parser powering the
[Angel](https://angel-dart.github.io)
framework. If you are looking for a server-side solution with dependency injection,
WebSockets, and more, then I highly recommend it as your first choice. Bam!

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

Body Parser exposes a simple class called `BodyParseResult`.
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
    return god.deserialize(await parseBody(request).body, MyClass);
}
```

## Custom Body Parsing
In cases where you need to parse unrecognized content types, `body_parser` won't be of any help to you
on its own. However, you can use the `originalBuffer` property of a `BodyParseResult` to see the original
request buffer. To get this functionality, pass `storeOriginalBuffer` as `true` when calling `parseBody`.

For example, if you wanted to
[parse GraphQL queries within your server](https://github.com/angel-dart/graphql)...

```dart
app.get('/graphql', (req, res) async {
  if (req.headers.contentType.mimeType == 'application/graphql') {
    var graphQlString = new String.fromCharCodes(req.originalBuffer);
    // ...
  }
});
```