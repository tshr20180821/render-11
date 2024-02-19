FROM php:8.3-apache

EXPOSE 80

# SHELL ["/bin/bash", "-c"]

WORKDIR /usr/src/app

COPY ./php.ini ${PHP_INI_DIR}/

RUN set -x \
 && ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
 && docker-php-ext-install opcache sockets

COPY --chmod=755 ./start.sh ./

STOPSIGNAL SIGWINCH

ENTRYPOINT ["/bin/bash","/usr/src/app/start.sh"]
