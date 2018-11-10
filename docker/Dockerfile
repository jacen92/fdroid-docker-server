FROM debian:stretch

LABEL Version="0.2"
LABEL Maintainer="Nicolas Gargaud <jacen92@gmail.com>"
LABEL Description="Simple fdroid repository"

ENV CONFIG_PY=config.py
ENV CONFIG_IN_PY=config.in.py
ENV CONFIG_EXTERNAL_PATH=/opt/config
ENV APK_EXTERNAL_PATH=/opt/apk
ENV HTML_INTERNAL_PATH=/var/www/html
ENV ENTRY_INTERNAL_PATH=/usr/bin/entrypoint.sh

# https://guardianproject.info/2013/11/05/setting-up-your-own-app-store-with-f-droid/

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
  && apt-get install -y apt-utils aapt nano htop wget python inotify-tools nginx fdroidserver \
  && rm -rf /var/lib/apt/lists/ \
  && cd "/var/www/html" && fdroid init && fdroid update -c && fdroid update

EXPOSE 80
COPY entrypoint.sh "$ENTRY_INTERNAL_PATH"
COPY default/$CONFIG_IN_PY "$HTML_INTERNAL_PATH/$CONFIG_IN_PY"
RUN chmod 0600 "$HTML_INTERNAL_PATH/$CONFIG_IN_PY" && chmod 0740 "$ENTRY_INTERNAL_PATH" \
  && mkdir "$APK_EXTERNAL_PATH" && mkdir "$CONFIG_EXTERNAL_PATH" \
  && cd "$HTML_INTERNAL_PATH" && python $CONFIG_IN_PY
VOLUME ["$APK_EXTERNAL_PATH", "$CONFIG_EXTERNAL_PATH"]
ENTRYPOINT "$ENTRY_INTERNAL_PATH"