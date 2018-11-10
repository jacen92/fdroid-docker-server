#!/bin/bash

echo "Copy apks from $APK_EXTERNAL_PATH"
cp "$APK_EXTERNAL_PATH/*.apk" "$HTML_INTERNAL_PATH/repo/" 2>/dev/null

if [ -f "$CONFIG_EXTERNAL_PATH/$CONFIG_PY" ]; then
  echo "Copy $CONFIG_PY from $CONFIG_EXTERNAL_PATH"
  cp "$CONFIG_EXTERNAL_PATH/$CONFIG_PY" "$HTML_INTERNAL_PATH/"
  chmod 0600 "$HTML_INTERNAL_PATH/$CONFIG_PY"
  if [ -f "$CONFIG_EXTERNAL_PATH/keystore.jks" ]; then
    echo "Copy keystore.jks from $CONFIG_EXTERNAL_PATH"
    cp "$CONFIG_EXTERNAL_PATH/keystore.jks" "$HTML_INTERNAL_PATH"
  else
    echo "No custom keystore.jks file found"
  fi
else
  echo "No custom $CONFIG_PY file found"
  if [ -f "$CONFIG_EXTERNAL_PATH/$CONFIG_IN_PY" ]; then
    echo "Copy $CONFIG_IN_PY from $CONFIG_EXTERNAL_PATH"
    cp "$CONFIG_EXTERNAL_PATH/$CONFIG_IN_PY" "$HTML_INTERNAL_PATH/"
  else
    echo "No custom $CONFIG_IN_PY file found"
  fi
  python "$HTML_INTERNAL_PATH/$CONFIG_IN_PY"
fi

echo "Run fdroid update"
cd "$HTML_INTERNAL_PATH" && fdroid update -c && fdroid update && cd -

echo "Starting nginx daemon"
nginx -g 'daemon off;' &

# TODO: find smarter way to achieve that...
echo "Monitoring apk directory"
inotifywait -m "$APK_EXTERNAL_PATH" -e create -e moved_to |
    while read path action file; do
        echo "The file '$file' appeared in directory '$path' via '$action'"
        sleep 10
        cp "$path$file" "$HTML_INTERNAL_PATH/repo/$file"
        cd "$HTML_INTERNAL_PATH" && fdroid update -c && fdroid update && cd -
    done
