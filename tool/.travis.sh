#!/usr/bin/env bash
cd angel_orm_generator
pub get
pub run build_runner build
POSTGRES_USERNAME="angel_orm" POSTGRES_PASSWORD="angel_orm" pub run test