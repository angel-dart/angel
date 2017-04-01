#!/usr/bin/env bash
set -e
pub run test
ANGEL_ENV=production pub run test