# ARCHIVED
Angel is no longer being maintained. You can read my reasons for discontinuing the project here: https://www.reddit.com/r/dartlang/comments/h0z413/looks_like_the_angel_webbackend_framework_wont_be/ftpaxmo/

At the moment, there is one fork of Angel that adds null-safety support. If you intend to upgrade
existing Angel projects to the more recent versions of Dart, then it's your best bet.

The fork can be found here: https://github.com/dukefirehawk/angel

Existing Angel projects have three options:
* Remain on an older version of the Dart VM
* Use the forked versions of the packages to support null-safety
* Switch to a new framework, and/or language

Thanks for 4 years. It was a fun ride, but it's time for me to move on. :wave:

---

[![The Angel Framework](https://angel-dart.github.io/assets/images/logo.png)](https://angel-dart.dev)

[![Gitter](https://img.shields.io/gitter/room/nwjs/nw.js.svg)](https://gitter.im/angel_dart/discussion)
[![Pub](https://img.shields.io/pub/v/angel_framework.svg)](https://pub.dartlang.org/packages/angel_framework)
[![Build status](https://travis-ci.org/angel-dart/framework.svg?branch=master)](https://travis-ci.org/angel-dart/framework)
![License](https://img.shields.io/github/license/angel-dart/framework.svg)

**A polished, production-ready backend framework in Dart.**

-----
## About
Angel is a full-stack Web framework in Dart. It aims to
streamline development by providing many common features
out-of-the-box in a consistent manner.

With features like the following, Angel is the all-in-one framework you should choose to build your next project:
* GraphQL Support
* PostgreSQL ORM
* Dependency Injection
* Static File Handling
* And much more...

See all the packages in the `packages/` directory.

## Installation & Setup

Once you have [Dart](https://www.dartlang.org/) installed, bootstrapping a project is as simple as running a few shell commands:

Install the [Angel CLI](https://github.com/angel-dart/cli):

```bash
pub global activate angel_cli
```

Bootstrap a project:

```bash
angel init hello
```

You can even have your server run and be *hot-reloaded* on file changes:

```bash
dart --observe bin/dev.dart
```

Next, check out the [detailed documentation](https://docs.angel-dart.dev/v/2.x) to learn to flesh out your project.

## Examples and Documentation
Visit the [documentation](https://docs.angel-dart.dev/v/2.x)
for dozens of guides and resources, including video tutorials,
to get up and running as quickly as possible with Angel.

Examples and complete projects can be found
[here](https://github.com/angel-dart/examples-v2).


You can also view the [API Documentation](http://www.dartdocs.org/documentation/angel_framework/latest).

There is also an [Awesome Angel :fire:](https://github.com/angel-dart/awesome-angel) list.

## Contributing
Interested in contributing to Angel? Start by reading the contribution guide [here](CONTRIBUTING.md).
