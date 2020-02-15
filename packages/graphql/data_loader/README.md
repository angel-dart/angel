# data_loader
[![Pub](https://img.shields.io/pub/v/data_loader.svg)](https://pub.dartlang.org/packages/data_loader)
[![build status](https://travis-ci.org/angel-dart/graphql.svg)](https://travis-ci.org/angel-dart/graphql)


Batch and cache database lookups. Works well with GraphQL.
Ported from the original JS version:
https://github.com/graphql/dataloader

## Installation
In your pubspec.yaml:

```yaml
dependencies:
  data_loader: ^1.0.0
```

## Usage
Complete example:
https://github.com/angel-dart/graphql/blob/master/data_loader/example/main.dart

```dart
var userLoader = new DataLoader((key) => myBatchGetUsers(keys));
var invitedBy = await userLoader.load(1)then(user => userLoader.load(user.invitedByID))
print('User 1 was invited by $invitedBy'));
```