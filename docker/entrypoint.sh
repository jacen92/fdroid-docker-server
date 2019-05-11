#!/bin/bash

# Set the directory to watch
export APK_DIR_TO_WATCH="$APK_EXTERNAL_PATH"

# If an user auth file is provided then copy, reset configuration and the directory to watch
if [ -f "$CONFIG_EXTERNAL_PATH/auth.txt" ]; then
  echo "Update fdroid scp password"
  chpasswd < "$CONFIG_EXTERNAL_PATH/auth.txt"
  sed -i -E 's/(.*)PasswordAuthentication (.*)/PasswordAuthentication yes/' /etc/ssh/sshd_config
  export APK_DIR_TO_WATCH="/home/fdroid"
else
  echo "No custom auth.txt file found in $CONFIG_EXTERNAL_PATH"
  sed -i -E 's/(.*)PasswordAuthentication (.*)/PasswordAuthentication no/' /etc/ssh/sshd_config
fi

# If an ssh key file is provided then copy, reset configuration and the directory to watch
if [ -f "$CONFIG_EXTERNAL_PATH/authorized_keys" ]; then
  echo "Copy fdroid scp keys"
  mkdir -p /home/fdroid/.ssh
  cp "$CONFIG_EXTERNAL_PATH/authorized_keys" /home/fdroid/.ssh/authorized_keys
  chown -R fdroid: /home/fdroid
  sed -i -E 's/(.*)PubkeyAuthentication (.*)/PubkeyAuthentication yes/' /etc/ssh/sshd_config
  export APK_DIR_TO_WATCH="/home/fdroid"
else
  echo "No custom authorized_keys file found in $CONFIG_EXTERNAL_PATH"
fi

# If an server config file is provided then copy else if config.in file is provided copy it
if [ -f "$CONFIG_EXTERNAL_PATH/$CONFIG_PY" ]; then
  echo "Copy $CONFIG_PY from $CONFIG_EXTERNAL_PATH"
  cp "$CONFIG_EXTERNAL_PATH/$CONFIG_PY" "$HTML_INTERNAL_PATH/"
  chmod 0600 "$HTML_INTERNAL_PATH/$CONFIG_PY"
else
  echo "No custom $CONFIG_PY file found"
  if [ -f "$CONFIG_EXTERNAL_PATH/$CONFIG_IN_PY" ]; then
    echo "Copy $CONFIG_IN_PY from $CONFIG_EXTERNAL_PATH"
    cp "$CONFIG_EXTERNAL_PATH/$CONFIG_IN_PY" "$HTML_INTERNAL_PATH/"
    python "$HTML_INTERNAL_PATH/$CONFIG_IN_PY"
  else
    echo "No custom $CONFIG_IN_PY file found in $CONFIG_EXTERNAL_PATH"
  fi
fi

# If a custom keystore file is provided then copy it
if [ -f "$CONFIG_EXTERNAL_PATH/keystore.jks" ]; then
  echo "Copy keystore.jks from $CONFIG_EXTERNAL_PATH"
  cp "$CONFIG_EXTERNAL_PATH/keystore.jks" "$HTML_INTERNAL_PATH"
else
  echo "No custom keystore.jks file found in $CONFIG_EXTERNAL_PATH"
fi

# Copy persistant apk files from persistant and home directories
echo "Copy apks from $APK_EXTERNAL_PATH"
find "/home/fdroid" -name '*.apk' -exec cp '{}' "$APK_EXTERNAL_PATH/" \;
find "$APK_EXTERNAL_PATH" -name '*.apk' -exec cp '{}' "$HTML_INTERNAL_PATH/repo/" \;

# Load fdroid server metadata from existing apk
echo "Run fdroid update"
cd "$HTML_INTERNAL_PATH" && fdroid update -c && fdroid update && cd -

echo "Starting nginx and ssh daemons"
nginx -g 'daemon off;' & /usr/sbin/sshd

# TODO: find smarter way to achieve that...
echo "Monitoring $APK_DIR_TO_WATCH directory"
inotifywait -m "$APK_DIR_TO_WATCH" -e close_write |
    while read path action file; do
        echo "The file '$file' appeared in directory '$path' via '$action'"
        if [ "${file: -4}" == ".apk" ]; then
          cp "$path$file" "$HTML_INTERNAL_PATH/repo/$file"
          cd "$HTML_INTERNAL_PATH" && fdroid update -c && fdroid update && cd -
          # Backup in persistant directory if using scp
          if [ $APK_DIR_TO_WATCH == "/home/fdroid" ]; then
            echo "Backup to persistant volume"
            cp "$path$file" "$APK_EXTERNAL_PATH/$file"
          fi
        elif [[ "${file: -4}" == ".zip" ]]; then
          echo "Not implemented for $file"
        else
          echo "Unknow file $file ... removed"
          rm -rf "$path$file"
        fi
    done
