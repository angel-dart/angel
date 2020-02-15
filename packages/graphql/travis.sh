#!/usr/bin/env bash
PWD=$(pwd)
cd "$PWD/graphql_parser" && pub get && pub run test -j2 && cd ..
cd "$PWD/graphql_schema" && pub get && pub run test -j2 && cd ..
cd "$PWD/graphql_server" && pub get && pub run test -j2 && cd ..
cd "$PWD/data_loader" && pub get && pub run test -j2 && cd ..