#!/usr/bin/env bash
cd graphql_parser && pub get && pub run test -j2 && cd ..
cd graphql_schema && pub get && pub run test -j2 && cd ..
cd graphql_server && pub get && pub run test -j2 && cd ..