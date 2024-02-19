FROM debian:stable-slim

EXPOSE 80

WORKDIR /app

COPY --chmod=755 ./start.sh ./

STOPSIGNAL SIGWINCH

ENTRYPOINT ["/bin/bash","/app/start.sh"]
