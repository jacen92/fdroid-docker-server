#!/bin/bash
# /usr/local/bin/remote-cmd.sh
echo "$SSH_ORIGINAL_COMMAND "
case $SSH_ORIGINAL_COMMAND in
 'scp'*)
    bash $SSH_ORIGINAL_COMMAND
    ;;
 *)
    echo "Access Denied"
    ;;
esac
