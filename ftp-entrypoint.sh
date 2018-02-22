#!/bin/sh

on_exit() {
  echo 'Exiting all jobs...'
  jobs -p | xargs kill
}
trap on_exit EXIT

# fork the vsftpd daemon and try to redirect everything to the log
vsftpd > /var/log/vsftpd.log 2>&1 &

# redirect the log to stdout for docker logs
tail -f /var/log/vsftpd.log
