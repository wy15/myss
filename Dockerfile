FROM golang:alpine as build

RUN apk add --no-cache ca-certificates git upx

WORKDIR /build

RUN set -ex \
    && git clone https://github.com/shadowsocks/v2ray-plugin \
    && cd v2ray-plugin \
    && CGO_ENABLED=0 go build -a -v -ldflags "-s -w" \
    && upx --best v2ray-plugin
#
# Dockerfile for shadowsocks-libev
#

FROM alpine
LABEL maintainer="kev <noreply@datageek.info>, Sah <contact@leesah.name>"
LABEL maintainer="mq83"
ENV TZ UTC

COPY --from=build /build/v2ray-plugin/v2ray-plugin /usr/bin/v2ray-plugin

#COPY . /tmp/repo
WORKDIR /tmp/repo
RUN set -ex \
 # Build environment setup
 && apk add --no-cache --virtual .build-deps \
      autoconf \
      automake \
      build-base \
      c-ares-dev \
      libcap \
      libev-dev \
      libtool \
      libsodium-dev \
      linux-headers \
      mbedtls-dev \
      pcre-dev \
      git \
 # Build & install
 && git clone --recursive https://github.com/shadowsocks/shadowsocks-libev.git \
# && cd /tmp/repo \
 && cd shadowsocks-libev \
 && ./autogen.sh \
 && ./configure --prefix=/usr --disable-documentation \
 && make -j8 \
 && make install \
 && ls /usr/bin/ss-* | xargs -n1 setcap cap_net_bind_service+ep \
 && apk del .build-deps \
 # Runtime dependencies setup
 && apk add --no-cache \
      ca-certificates \
      rng-tools \
      tini \
      tzdata \
      $(scanelf --needed --nobanner /usr/bin/ss-* \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | sort -u) \
 && rm -rf /tmp/repo

USER nobody

ENTRYPOINT ["/sbin/tini", "--"]
