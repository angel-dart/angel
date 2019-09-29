#!/usr/bin/env bash

# Install Dart, globally.
sudo apt-get update
sudo apt-get install apt-transport-https
sudo sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update
sudo apt-get install -y dart
export PATH="$PATH:/usr/lib/dart/bin"
echo 'export PATH="$PATH:/usr/lib/dart/bin"' >> ~vagrant/.profile

# Install build tooling, CMake, etc.
sudo apt-get install -y build-essential
sudo apt-get install -y cmake

# Build the library.
pushd /vagrant
mkdir -p cmake-build-vagrant
pushd cmake-build-vagrant
cmake ..
cmake --build . --target install
popd
popd
