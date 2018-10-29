FROM wombat/alpine:v0.1 AS mirror

RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
RUN apk add --no-cache --initdb -p /out \
    nfs-utils \
    rpcbind \
    iptables \
    bind \
    bind-tools \
    && true
RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache

ADD nfs.sh /out/usr/bin/nfs.sh

FROM scratch
ENTRYPOINT []
WORKDIR /
COPY --from=mirror /out/ /
COPY etc/ /etc/
RUN echo "nfs             2049/tcp" >> /etc/services
RUN echo "nfs             111/udp" >> /etc/services
EXPOSE 2049/tcp 111/tcp 111/udp
CMD ["/usr/bin/nfs.sh"]
