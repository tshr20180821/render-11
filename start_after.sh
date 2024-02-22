#!/bin/bash

set -x

export PS4='+(${BASH_SOURCE}:${LINENO}): '

mkdir /app/fah

curl -sSO https://download.foldingathome.org/releases/public/release/fahclient/debian-stable-64bit/v7.6/latest.deb

DEBIAN_FRONTEND=noninteractive apt-get install -y ./latest.deb
rm ./latest.deb

DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  iproute2 \
  megatools

echo "[Login]" >/root/.megarc
echo "Username = ${MEGA_EMAIL}" >>/root/.megarc
echo "Password = ${MEGA_PASSWORD}" >>/root/.megarc

FAHClient --help >/var/www/html/auth/fahclient.txt
# FAHClient --lspci >/var/www/html/auth/lspci.txt

megatools mkdir /Root/${RENDER_EXTERNAL_HOSTNAME}
megatools get /Root/${RENDER_EXTERNAL_HOSTNAME}/fah.tar.gz
tar xf ./fah.tar.gz
rm -f ./fah.tar.gz

ls -lang /app/fah/

while true; do \
  for i in {1..10}; do \
    sleep 60s; \
    curl -sSA "${i}" -u "${BASIC_USER}":"${BASIC_PASSWORD}" https://"${RENDER_EXTERNAL_HOSTNAME}"/ >/dev/null; \
  done \
   && ss -anpt \
   && ps aux \
   && TARGET_PID=$(ps -e -o pid,cmd | grep /app/fah/cores/ | grep -v FAHCoreWrapper | grep -v grep | awk '{ print $1 }') \
   && du -hd 1 /app/fah \
   && rm -f /app/fah/logs/* \
   && rm -f /tmp/fah.tar.gz \
   && renice -n 10 ${TARGET_PID} \
   && tar -zcf /tmp/fah.tar.gz ./fah \
   && megatools rm --no-ask-password /Root/${RENDER_EXTERNAL_HOSTNAME}/fah.tar.gz | true \
   && ls -lang /tmp/fah.tar.gz \
   && megatools put --no-ask-password --path /Root/${RENDER_EXTERNAL_HOSTNAME}/fah.tar.gz /tmp/fah.tar.gz \
   && renice -n 0 ${TARGET_PID}; \
done &

while true; do \
  FAHClient --gpu=false --chdir=/app/fah --power=full --http-addresses=127.0.0.1:7396 --command-address=127.0.0.1 \
   --max-packet-size=small --checkpoint=5 --log-header=false --log-rotate-max=2 --log-time=false;
done

