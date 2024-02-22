#!/bin/bash

set -x

export PS4='+(${BASH_SOURCE}:${LINENO}): '

mkdir /app/fah

curl -sSO https://download.foldingathome.org/releases/public/release/fahclient/debian-stable-64bit/v7.6/latest.deb

DEBIAN_FRONTEND=noninteractive apt-get install -y ./latest.deb
rm ./latest.deb

DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
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

ls -lang
ls -lang /app/fah/

while true; do \
  for i in {1..10}; do \
    sleep 60s \
     && curl -sS -A "${i}" -u "${BASIC_USER}":"${BASIC_PASSWORD}" https://"${RENDER_EXTERNAL_HOSTNAME}"/; \
  done \
   && ss -anpt \
   && ps aux \
   && rm -f /tmp/fah.tar.gz \
   && tar -zcf /tmp/fah.tar.gz ./fah \
   && megatools rm --no-ask-password /Root/${RENDER_EXTERNAL_HOSTNAME}/fah.tar.gz | true \
   && megatools put --no-ask-password --path /Root/${RENDER_EXTERNAL_HOSTNAME}/fah.tar.gz /tmp/fah.tar.gz; \
done &

while true; do \
  FAHClient -v --gpu=false --chdir=/app/fah --power=full --http-addresses=127.0.0.1:7396 --command-address=127.0.0.1 \
   --max-packet-size=small --verbosity=5 --exit-when-done=true --checkpoint=3 \
    && rm -f /app/fah/logs/* \
    && megatools rm --no-ask-password /Root/${RENDER_EXTERNAL_HOSTNAME}/fah.tar.gz; \
done
