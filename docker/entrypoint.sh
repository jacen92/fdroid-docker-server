#!/bin/bash

# Set the directory to watch
export APK_DIR_TO_WATCH="$EXTERNAL_APK_STORAGE"

function configure_nginx {
  echo "Configure nginx"
  sed -i -E '/listen \[::\]:80 default_server/d' "/etc/nginx/sites-enabled/default"
}

function configure_ssh_server {
  echo "Configure ssh server for user $USERNAME"
  cat >>/etc/ssh/sshd_config <<EOL
# Example of overriding settings on a per-user basis
Match User $USERNAME
       X11Forwarding no
       AllowTcpForwarding no
       PermitTTY no
       # ForceCommand /usr/local/bin/remote-cmd.sh
EOL
}

function configure_ssh_authentication {
  # If an user auth file is provided then copy, reset configuration and the directory to watch
  if [ -f "$EXTERNAL_CONFIG_PATH/auth.txt" ]; then
    echo "Update fdroid scp password"
    chpasswd < "$EXTERNAL_CONFIG_PATH/auth.txt"
    sed -i -E 's/(.*)PasswordAuthentication (.*)/PasswordAuthentication yes/' /etc/ssh/sshd_config
  else
    echo "No custom auth.txt file found in $EXTERNAL_CONFIG_PATH"
    sed -i -E 's/(.*)PasswordAuthentication (.*)/PasswordAuthentication no/' /etc/ssh/sshd_config
  fi

  # If an ssh authorized_keys file is provided then copy, reset configuration and the directory to watch
  if [ -f "$EXTERNAL_CONFIG_PATH/authorized_keys" ]; then
    echo "Copy fdroid scp keys"
    mkdir -p /home/$USERNAME/.ssh
    cp "$EXTERNAL_CONFIG_PATH/authorized_keys" /home/$USERNAME/.ssh/authorized_keys
    sed -i -E 's/(.*)PubkeyAuthentication (.*)/PubkeyAuthentication yes/' /etc/ssh/sshd_config
  else
    echo "No custom authorized_keys file found in $EXTERNAL_CONFIG_PATH"
    sed -i -E 's/(.*)PubkeyAuthentication (.*)/PubkeyAuthentication no/' /etc/ssh/sshd_config
  fi
}

function configure_keystore {
  # If a custom keystore file is provided then copy it
  if [ -f "$EXTERNAL_CONFIG_PATH/keystore.jks" ]; then
    echo "Copy keystore.jks from $EXTERNAL_CONFIG_PATH"
    cp "$EXTERNAL_CONFIG_PATH/keystore.jks" "$INTERNAL_HTML_PATH"
  else
    echo "No custom keystore.jks file found in $EXTERNAL_CONFIG_PATH"
  fi
}

function register_existing_apk {
  # Copy persistant apk files from persistant to nginx directory
  echo "Register apks from $EXTERNAL_APK_STORAGE"
  find "$EXTERNAL_APK_STORAGE" -name '*.apk' -exec cp '{}' "$INTERNAL_HTML_PATH/repo/" \;
}

function customize_fdroid {
  # If an server config file is provided then copy else if config.in file is provided copy it
  if [ -f "$EXTERNAL_CONFIG_PATH/$CONFIG_PY" ]; then
    echo "Copy $CONFIG_PY from $EXTERNAL_CONFIG_PATH"
    cp "$EXTERNAL_CONFIG_PATH/$CONFIG_PY" "$INTERNAL_HTML_PATH/"
    chmod 0600 "$INTERNAL_HTML_PATH/$CONFIG_PY"
  else
    echo "No custom $CONFIG_PY file found"
    if [ -f "$EXTERNAL_CONFIG_PATH/$CONFIG_IN_PY" ]; then
      echo "Copy $CONFIG_IN_PY from $EXTERNAL_CONFIG_PATH"
      cp "$EXTERNAL_CONFIG_PATH/$CONFIG_IN_PY" "$INTERNAL_HTML_PATH/"
      python "$INTERNAL_HTML_PATH/$CONFIG_IN_PY"
    else
      echo "No custom $CONFIG_IN_PY file found in $EXTERNAL_CONFIG_PATH"
    fi
  fi
}

function update_fdroid
{
  echo "Generate fdroid static data"
  cd "$INTERNAL_HTML_PATH" && fdroid update -c && fdroid update && cd -
}

function watch_and_update {
  # TODO: find smarter way to achieve that...
  echo "Monitoring $APK_DIR_TO_WATCH directory"
  inotifywait -m "$APK_DIR_TO_WATCH" -e close_write |
      while read path action file; do
          echo "The file '$file' appeared in directory '$path' via '$action'"
          if [ "${file: -4}" == ".apk" ]; then
            cp "$path$file" "$INTERNAL_HTML_PATH/repo/$file"
            update_fdroid

          elif [[ "${file: -4}" == ".zip" ]]; then
            echo "Not implemented for $file"
          else
            echo "Unknow file $file ... removed"
            rm -rf "$path$file"
          fi
      done
}

# prepare system
configure_nginx
configure_ssh_server
configure_ssh_authentication
#configure_keystore
#customize_fdroid

# Load fdroid server metadata from existing apk
#register_existing_apk
#update_fdroid

echo "Starting nginx and ssh daemons"
nginx -g 'daemon off;' & /usr/sbin/sshd

watch_and_update
