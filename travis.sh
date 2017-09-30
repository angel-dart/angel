#!/usr/bin/env bash
cd jael && pub get && pub run test
cd ../jael_preprocessor/ && pub get && pub run test
