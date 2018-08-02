#!/usr/bin/env bash
set -e
set -x
cd graphql_parser && pub get && pub run test -j2 && cd..