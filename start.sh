#!/bin/bash

set -x

export PS4='+(${BASH_SOURCE}:${LINENO}): '

apt-get -qq update
DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
  apache2 \
  ca-certificates \
  curl \
  iproute2

a2dissite -q 000-default.conf

mkdir -p /var/www/html/auth

chown www-data:www-data /var/www/html/auth -R

echo '<HTML />' >/var/www/html/index.html

{ \
  echo 'User-agent: *'; \
  echo 'Disallow: /'; \
} >/var/www/html/robots.txt

a2enmod \
 authz_groupfile \
 proxy \
 proxy_http

mv /etc/apache2/apache2.conf /etc/apache2/apache2.conf.org

curl -sSL -o /etc/apache2/apache2.conf https://github.com/tshr20180821/render-11/raw/main/apache.conf
sed -i s/__RENDER_EXTERNAL_HOSTNAME__/"${RENDER_EXTERNAL_HOSTNAME}"/g /etc/apache2/apache2.conf

htpasswd -c -b /var/www/html/.htpasswd "${BASIC_USER}" "${BASIC_PASSWORD}"
chmod 644 /var/www/html/.htpasswd
. /etc/apache2/envvars >/dev/null 2>&1

ls -lang /etc/apache2/

curl -sSL -O https://github.com/tshr20180821/render-10/raw/main/start_after.sh

chmod +x ./start_after.sh

sleep 5s && ./start_after.sh &

exec /usr/sbin/apache2 -DFOREGROUND
