#!/usr/bin/env bash
# Fast-fail on errors
set -e

cd jael && pub get && pub run test
cd ../jael_preprocessor/ && pub get && pub run test
cd ../angel_jael/ && pub get && pub run test
