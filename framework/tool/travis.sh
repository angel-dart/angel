#!/usr/bin/env bash
set -e
pub run test --timeout 5s
ANGEL_ENV=production pub run test --timeout 5s