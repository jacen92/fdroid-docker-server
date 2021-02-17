FROM ubuntu:20.04

LABEL Version="1.0"
LABEL Maintainer="Nicolas Gargaud <jacen92@gmail.com>"
LABEL Description="Simple standalone fdroid repository"

ENV USERNAME fdroid_deploy
ENV CONFIG_PY=config.py
ENV CONFIG_IN_PY=config.in.py
ENV INTERNAL_HTML_PATH=/var/www/html
ENV EXTERNAL_CONFIG_PATH=/opt/config
ENV EXTERNAL_APK_STORAGE=/opt/apk
ENV ENTRYPOINT_PATH=/usr/bin/entrypoint.sh

# https://guardianproject.info/2013/11/05/setting-up-your-own-app-store-with-f-droid/
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
  && apt-get install -y software-properties-common aapt nano htop wget python3 python3-pip inotify-tools nginx openssh-server \
  && rm -rf /var/lib/apt/lists/ \
  && mkdir /var/run/sshd \
  && sed -i -E 's/(.*)PermitRootLogin (.*)/PermitRootLogin no/' /etc/ssh/sshd_config \
  && sed -i -E 's/(.*)allowscp(.*)/allowscp/' /etc/ssh/sshd_config

#RUN cd "/var/www/html" && fdroid init && fdroid update -c && fdroid update

# Use ssh restricted to scp to send apk to the shared directory
# https://www.interserver.net/tips/kb/install-setup-rssh-scponly/
RUN useradd -m -d "/home/$USERNAME" -s /bin/bash $USERNAME \
  && mkdir "$EXTERNAL_APK_STORAGE" \
  && chown $USERNAME:$USERNAME "$EXTERNAL_APK_STORAGE"

COPY entrypoint.sh "$ENTRYPOINT_PATH"
COPY default/remote.sh "/usr/local/bin/remote-cmd.sh"
RUN chmod +x "$ENTRYPOINT_PATH" && chmod +x "/usr/local/bin/remote-cmd.sh"
EXPOSE 80 22
VOLUME ["$EXTERNAL_APK_STORAGE", "$EXTERNAL_CONFIG_PATH"]
ENTRYPOINT $ENTRYPOINT_PATH
