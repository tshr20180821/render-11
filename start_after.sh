#!/bin/bash

set -x

export PS4='+(${BASH_SOURCE}:${LINENO}): '

log_check() {
  tail -n 1 /app/fah/log.txt >/tmp/logtail.txt
  if [ -f /tmp/logtail.txt.old ]; then
    if [ "1" = "$(diff -q /tmp/logtail.txt.old /tmp/logtail.txt | grep -c differ)" ]; then
      curl -sS -H "Authorization: Bearer ${SLACK_TOKEN}" \
        -d "text=${RENDER_EXTERNAL_HOSTNAME} $(cat /tmp/logtail.txt)" -d "channel=${SLACK_CHANNEL_02}" \
        https://slack.com/api/chat.postMessage >/dev/null
    fi
  fi
  cp -f /tmp/logtail.txt /tmp/logtail.txt.old
}

curl -sSO https://download.foldingathome.org/releases/public/release/fahclient/debian-stable-64bit/v7.6/latest.deb &

DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  iproute2 \
  jq \
  megatools &

FAH_USER="${RENDER_EXTERNAL_HOSTNAME//.onrender.com/}"

if [ -z "${FAH_TEAM_NUMBER}" ]; then
  FAH_TEAM_NUMBER=0
fi

mkdir /app/fah

echo "[Login]" >/root/.megarc
echo "Username = ${MEGA_EMAIL}" >>/root/.megarc
echo "Password = ${MEGA_PASSWORD}" >>/root/.megarc

wait

DEBIAN_FRONTEND=noninteractive apt-get install -y ./latest.deb &

if [ -n "${SLACK_TOKEN}" ]; then
  RANK=$(curl -sS https://api.foldingathome.org/team/"${FAH_TEAM_NUMBER}" | jq '.rank')

  curl -sS -H "Authorization: Bearer ${SLACK_TOKEN}" \
    -d "text=RESTART ${RENDER_EXTERNAL_HOSTNAME} RANK:${RANK}" -d "channel=${SLACK_CHANNEL_01}" https://slack.com/api/chat.postMessage >/dev/null

  sleep 1s

  curl -sS -H "Authorization: Bearer ${SLACK_TOKEN}" \
    -d "text=RESTART ${RENDER_EXTERNAL_HOSTNAME} RANK:${RANK}" -d "channel=${SLACK_CHANNEL_02}" https://slack.com/api/chat.postMessage >/dev/null
fi

megatools mkdir /Root/"${RENDER_EXTERNAL_HOSTNAME}"
megatools get /Root/"${RENDER_EXTERNAL_HOSTNAME}"/fah.tar.gz
tar xf ./fah.tar.gz
rm -f ./fah.tar.gz

ls -lang /app/fah/
touch /app/fah/log.txt
ln -s /app/fah/log.txt /var/www/html/auth/log.txt

wait

rm ./latest.deb

FAHClient --help >/var/www/html/auth/fahclient.txt

while true; do \
  for i in {1..30}; do \
    sleep 60s; \
    curl -sSA "${i}" -u "${BASIC_USER}":"${BASIC_PASSWORD}" https://"${RENDER_EXTERNAL_HOSTNAME}"/ >/dev/null; \
  done \
   && ss -anpt \
   && ps aux \
   && du -hd 1 /app/fah \
   && ls -lang /app/fah/ \
   && rm -f /tmp/fah.tar.gz \
   && tar -zcf /tmp/fah.tar.gz ./fah \
   && megatools rm --no-ask-password /Root/"${RENDER_EXTERNAL_HOSTNAME}"/fah.tar.gz | true \
   && ls -lang /tmp/fah.tar.gz \
   && megatools put --no-ask-password --path /Root/"${RENDER_EXTERNAL_HOSTNAME}"/fah.tar.gz /tmp/fah.tar.gz \
   && log_check; \
done &

while true; do \
  FAHClient --gpu=false --chdir=/app/fah --power=full --http-addresses=127.0.0.1:7396 --command-address=127.0.0.1 --cpu-usage=20 \
   --max-packet-size=small --checkpoint=5 --log-header=false --log-rotate-max=2 --team="${FAH_TEAM_NUMBER}" --user="${FAH_USER}";
done
