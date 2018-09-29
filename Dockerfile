## >> Build
FROM golang:1.10.2-alpine as builder

ARG CADDY_VERSION="0.11.0"

# clone caddy
RUN \
  apk add --no-cache git && \
  git clone https://github.com/caddyserver/builds /go/src/github.com/caddyserver/builds && \
  git clone https://github.com/mholt/caddy -b "v$CADDY_VERSION" /go/src/github.com/mholt/caddy && \
    cd /go/src/github.com/mholt/caddy && \
    git checkout -b "v$CADDY_VERSION" && \
    
  # Disable Telemetry
  sed -i -e 's#EnableTelemetry = true#EnableTelemetry = false#' /go/src/github.com/mholt/caddy/caddy/caddymain/run.go && \
  echo ">> Telemetry : Disabled"

# import plugins
#COPY plugins.go /go/src/github.com/mholt/caddy/caddyhttp/plugins.go

# build caddy
RUN \
  cd /go/src/github.com/mholt/caddy/caddy && \
    go get ./... && \
    go run build.go && \
    mv caddy /go/bin

## >> Caddy image
FROM alpine:3.8

# copy caddy binary
COPY --from=builder /go/bin/caddy /usr/bin/caddy

# install deps
RUN \
  apk add --no-cache --no-progress \ 
    curl \
    tini \
    ca-certificates && \
  /usr/bin/caddy -plugins

COPY Caddyfile /etc/caddy/Caddyfile

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["caddy", "-agree", "--conf", "/etc/caddy/Caddyfile"]
