FROM ubuntu:14.04
MAINTAINER Tobe O <thosakwe@gmail.com>

# Install Dart SDK 1.21.0
RUN sudo apt-get update
RUN sudo apt-get install -y apt-transport-https
RUN sudo apt-get install -y curl
RUN sudo sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
RUN sudo sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
RUN sudo apt-get update
RUN sudo apt-get install -y dart=1.21.0-1
RUN export PATH="/usr/lib/dart/bin:$PATH"

# Copy necessary files
ADD bin/ bin/
ADD config/ config/
ADD lib/ lib/
ADD tool/ tool/
ADD views/ views/
ADD web/ web/
ADD pubspec.yaml pubspec.yaml

# Install dependencies, pre-build
RUN /usr/lib/dart/bin/pub get
RUN /usr/lib/dart/bin/dart tool/build.dart
RUN /usr/lib/dart/bin/pub build

# Set environment, start multi-server :)
ENV ANGEL_ENV=production
EXPOSE 3000
ENTRYPOINT ["/usr/lib/dart/bin/dart"]
CMD ["bin/multi_server.dart"]