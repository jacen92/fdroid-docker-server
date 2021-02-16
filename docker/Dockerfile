FROM ubuntu:20.04

LABEL Version="1.0"
LABEL Maintainer="Nicolas Gargaud <jacen92@gmail.com>"
LABEL Description="Simple standalone fdroid repository"

ENV CONFIG_PY=config.py
ENV CONFIG_IN_PY=config.in.py
ENV CONFIG_EXTERNAL_PATH=/opt/config
ENV APK_EXTERNAL_PATH=/opt/apk
ENV HTML_INTERNAL_PATH=/var/www/html
ENV ENTRY_INTERNAL_PATH=/usr/bin/entrypoint.sh

# https://guardianproject.info/2013/11/05/setting-up-your-own-app-store-with-f-droid/

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
  && apt-get install -y software-properties-common aapt nano htop wget python3 python3-pip inotify-tools nginx fdroidserver openssh-server \
  && rm -rf /var/lib/apt/lists/ \
  && mkdir /var/run/sshd && cd "/var/www/html" && fdroid init && fdroid update -c && fdroid update

# Use ssh restricted to scp to send apk to the shared directory
# https://www.interserver.net/tips/kb/install-setup-rssh-scponly/
#
RUN useradd -m -d "/home/fdroid" -s /bin/bash fdroid
RUN sed -i -E 's/(.*)PermitRootLogin (.*)/PermitRootLogin no/' /etc/ssh/sshd_config
RUN sed -i -E 's/(.*)allowscp(.*)/allowscp/' /etc/ssh/sshd_config

COPY entrypoint.sh "$ENTRY_INTERNAL_PATH"
RUN chmod 0740 "$ENTRY_INTERNAL_PATH" && cd "$HTML_INTERNAL_PATH"
EXPOSE 80 22
VOLUME ["$APK_EXTERNAL_PATH", "$CONFIG_EXTERNAL_PATH"]
ENTRYPOINT $ENTRY_INTERNAL_PATH
