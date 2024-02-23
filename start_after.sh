#!/bin/bash

set -x

export PS4='+(${BASH_SOURCE}:${LINENO}): '

curl -sSO https://download.foldingathome.org/releases/public/release/fahclient/debian-stable-64bit/v7.6/latest.deb &

DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  iproute2 \
  jq \
  megatools &

FAH_USER=$(echo ${RENDER_EXTERNAL_HOSTNAME} | sed 's/.onrender.com//')

if [ -z ${FAH_TEAM_NUMBER} ]; then
  FAH_TEAM_NUMBER=0
fi

mkdir /app/fah

echo "[Login]" >/root/.megarc
echo "Username = ${MEGA_EMAIL}" >>/root/.megarc
echo "Password = ${MEGA_PASSWORD}" >>/root/.megarc

wait

DEBIAN_FRONTEND=noninteractive apt-get install -y ./latest.deb &

if [ ! -z ${SLACK_TOKEN} ]; then
  RANK=$(curl -sS https://api.foldingathome.org/team/${FAH_TEAM_NUMBER} | jq '.rank')

  curl -sS -X POST -H "Authorization: Bearer ${SLACK_TOKEN}" \
    -d "text=RESTART ${RENDER_EXTERNAL_HOSTNAME} RANK:${RANK}" -d "channel=${SLACK_CHANNEL_01}" https://slack.com/api/chat.postMessage >/dev/null

  sleep 1s

  curl -sS -X POST -H "Authorization: Bearer ${SLACK_TOKEN}" \
    -d "text=RESTART ${RENDER_EXTERNAL_HOSTNAME} RANK:${RANK}" -d "channel=${SLACK_CHANNEL_02}" https://slack.com/api/chat.postMessage >/dev/null
fi

wait

rm ./latest.deb

FAHClient --help >/var/www/html/auth/fahclient.txt
# FAHClient --lspci >/var/www/html/auth/lspci.txt

megatools mkdir /Root/${RENDER_EXTERNAL_HOSTNAME}
megatools get /Root/${RENDER_EXTERNAL_HOSTNAME}/fah.tar.gz
tar xf ./fah.tar.gz
rm -f ./fah.tar.gz

ls -lang /app/fah/

while true; do \
  for i in {1..30}; do \
    sleep 60s; \
    curl -sSA "${i}" -u "${BASIC_USER}":"${BASIC_PASSWORD}" https://"${RENDER_EXTERNAL_HOSTNAME}"/ >/dev/null; \
  done \
   && ss -anpt \
   && ps aux \
   && du -hd 1 /app/fah \
   && rm -f /app/fah/logs/* \
   && rm -f /tmp/fah.tar.gz \
   && tar -zcf /tmp/fah.tar.gz ./fah \
   && megatools rm --no-ask-password /Root/${RENDER_EXTERNAL_HOSTNAME}/fah.tar.gz | true \
   && ls -lang /tmp/fah.tar.gz \
   && megatools put --no-ask-password --path /Root/${RENDER_EXTERNAL_HOSTNAME}/fah.tar.gz /tmp/fah.tar.gz; \
done &

while true; do \
  FAHClient --gpu=false --chdir=/app/fah --power=full --http-addresses=127.0.0.1:7396 --command-address=127.0.0.1 \
   --max-packet-size=small --checkpoint=5 --log-header=false --log-rotate-max=2 --log-time=false --team=${FAH_TEAM_NUMBER} --user=${FAH_USER};
done

