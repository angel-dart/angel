#!/usr/bin/env bash
cd angel_orm_generator
pub get
dart tool/build.dart
POSTGRES_USERNAME="angel_orm" POSTGRES_PASSWORD="angel_orm" pub run test