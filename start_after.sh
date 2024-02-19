#!/bin/bash

set -x

export PS4='+(${BASH_SOURCE}:${LINENO}): '

while true; do \
  for i in {1..10}; do \
    sleep 60s \
     && echo "${i}"; \
  done \
   && ss -anpt \
   && ps aux \
   && FAHClient --queue-info \
   && curl -sS -A "keep instance" -u "${BASIC_USER}":"${BASIC_PASSWORD}" https://"${RENDER_EXTERNAL_HOSTNAME}"/; \
done &

curl -sSO https://download.foldingathome.org/releases/public/release/fahclient/debian-stable-64bit/v7.6/latest.deb

DEBIAN_FRONTEND=noninteractive apt-get -y install ./latest.deb
rm ./latest.deb

FAHClient --help >/var/www/html/auth/fahclient.txt
FAHClient --lspci >/var/www/html/auth/lspci.txt

while true; do \
  FAHClient -v --user=Anonymous --team=0 --gpu=false --cpus=-1 --chdir=/tmp --log-to-screen=true --power=full \
   --http-addresses=127.0.0.1:7396 --command-address=127.0.0.1 --max-packet-size=small --core-priority=low --verbosity=5; \
done

