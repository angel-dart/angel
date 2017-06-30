#!/usr/bin/env bash
set -e
dart test/all.dart
ANGEL_ENV=production dart test/all.dart