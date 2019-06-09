FROM kubernit/alpine:v0.1 AS mirror

RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
RUN apk add --no-cache --initdb -p /out \
    alpine-baselayout \
    apk-tools \
    busybox \
    ca-certificates \
    coreutils \
    curl \
    ebtables \
    ethtool \
    findutils \
    iproute2 \
    iptables \
    musl \
    openssl \
    openrc \
    rpcbind \
    socat \
    util-linux \
    nfs-utils \
    && true
RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache

ADD nfs.sh /out/usr/bin/nfs.sh

FROM scratch
ENTRYPOINT []
WORKDIR /
COPY --from=mirror /out/ /
COPY etc/ /etc/
EXPOSE 2049/tcp 111/tcp 111/udp
ENTRYPOINT ["/usr/bin/nfs.sh"]
