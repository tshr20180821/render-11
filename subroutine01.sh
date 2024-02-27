#!/bin/bash

set -x

export PS4='+(${BASH_SOURCE}:${LINENO}): '

ss -anpt
ps aux
du -hd 1 /app/fah
ls -lang /app/fah/
rm -f /tmp/fah.tar.xz
tar cfJ /tmp/fah.tar.xz ./fah
megatools rm --no-ask-password /Root/"${RENDER_EXTERNAL_HOSTNAME}"/fah.tar.gz
megatools rm --no-ask-password /Root/"${RENDER_EXTERNAL_HOSTNAME}"/fah.tar.xz
ls -lang /tmp/fah.tar.xz
megatools put --no-ask-password --path /Root/"${RENDER_EXTERNAL_HOSTNAME}"/fah.tar.xz /tmp/fah.tar.xz
# grep steps /app/fah/log.txt | tail -n 1 >/tmp/logtail.txt
cat /app/fah/log.txt | grep steps | tail -n 1 >/tmp/logtail.txt
cat /tmp/logtail.txt
if [ -f /tmp/logtail.txt.old ]; then
  if [ "1" = "$(diff -q /tmp/logtail.txt.old /tmp/logtail.txt | grep -c differ)" ]; then
    curl -sSH "Authorization: Bearer ${SLACK_TOKEN}" \
      -d "text=${RENDER_EXTERNAL_HOSTNAME} $(cat /tmp/logtail.txt)" -d "channel=${SLACK_CHANNEL_01}" \
      https://slack.com/api/chat.postMessage >/dev/null
    sleep 1s
    curl -sSH "Authorization: Bearer ${SLACK_TOKEN}" \
      -d "text=${RENDER_EXTERNAL_HOSTNAME} $(cat /tmp/logtail.txt)" -d "channel=${SLACK_CHANNEL_02}" \
      https://slack.com/api/chat.postMessage >/dev/null
  fi
fi
cp -f /tmp/logtail.txt /tmp/logtail.txt.old
