FROM golang:1.11.1-alpine3.7 AS build

# When changing kubernetes_version remember to also update:
# - scripts/mk-image-cache-lst and run `make refresh-image-caches` from top-level
# - pkg/e2e-test/Dockerfile
ENV kubernetes_version v1.12.0
ENV cni_version        v0.7.1
ENV critools_version   v1.11.1
ENV helm_version       v2.9.1

RUN apk add -U --no-cache \
  bash \
  coreutils \
  curl \
  findutils \
  git \
  go \
  grep \
  libc-dev \
  linux-headers \
  make \
  rsync \
  gcc \
  glide \
  mercurial \
  && true

ENV GOPATH=/go PATH=$PATH:/go/bin

### Kubernetes (incl Kubelet)

ENV KUBERNETES_URL https://github.com/kubernetes/kubernetes.git
#ENV KUBERNETES_BRANCH pull/NNN/head
ENV KUBERNETES_COMMIT ${kubernetes_version}
RUN mkdir -p $GOPATH/src/github.com/kubernetes && \
    cd $GOPATH/src/github.com/kubernetes && \
    git clone $KUBERNETES_URL kubernetes
WORKDIR $GOPATH/src/github.com/kubernetes/kubernetes
RUN set -e; \
    if [ -n "$KUBERNETES_BRANCH" ] ; then \
        git fetch origin "$KUBERNETES_BRANCH"; \
    fi; \
    git checkout -q $KUBERNETES_COMMIT

RUN make WHAT="cmd/kubelet cmd/kubectl cmd/kubeadm"

### CNI plugins

ENV CNI_URL https://github.com/containernetworking/plugins
#ENV CNI_BRANCH pull/NNN/head
ENV CNI_COMMIT ${cni_version}
RUN mkdir -p $GOPATH/github.com/containernetworking/ && \
    cd $GOPATH/github.com/containernetworking/ && \
    git clone $CNI_URL plugins
WORKDIR $GOPATH/github.com/containernetworking/plugins
RUN set -e;  \
    if [ -n "$CNI_BRANCH" ] ; then \
        git fetch origin "CNI_BRANCH"; \
    fi; \
    git checkout -q $CNI_COMMIT
RUN ./build.sh

### critools

ENV CRITOOLS_URL https://github.com/kubernetes-incubator/cri-tools
#ENV CRITOOLS_BRANCH pull/NNN/head
ENV CRITOOLS_COMMIT ${critools_version}
RUN mkdir -p $GOPATH/github.com/kubernetes-incubator/ && \
    cd $GOPATH/github.com/kubernetes-incubator/ && \
    git clone $CRITOOLS_URL cri-tools
WORKDIR $GOPATH/github.com/kubernetes-incubator/cri-tools
RUN set -e;  \
    if [ -n "$CRITOOLS_BRANCH" ] ; then \
        git fetch origin "CRITOOLS_BRANCH"; \
    fi; \
    git checkout -q $CRITOOLS_COMMIT
RUN make binaries

### helm

ENV HELM_URL https://github.com/kubernetes/helm.git
#ENV KUBERNETES_BRANCH pull/NNN/head
ENV HELM_COMMIT ${helm_version}
RUN mkdir -p $GOPATH/src/k8s.io && \
    cd $GOPATH/src/k8s.io && \
    git clone $HELM_URL helm
WORKDIR $GOPATH/src/k8s.io/helm
RUN set -e; \
    if [ -n "$HELM_BRANCH" ] ; then \
        git fetch origin "$HELM_BRANCH"; \
    fi; \
    git checkout -q $HELM_COMMIT
RUN glide install && make bootstrap build
RUN ./bin/helm init --client-only

## Construct final image

RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
RUN apk add --no-cache --initdb -p /out \
    busybox \
    coreutils \
    ebtables \
    ethtool \
    findutils \
    iproute2 \
    iptables \
    musl \
    openssl \
    socat \
    util-linux \
    nfs-utils \
    && true

RUN cp $GOPATH/src/github.com/kubernetes/kubernetes/_output/bin/kubelet /out/usr/bin/kubelet
RUN cp $GOPATH/src/github.com/kubernetes/kubernetes/_output/bin/kubeadm /out/usr/bin/kubeadm
RUN cp $GOPATH/src/github.com/kubernetes/kubernetes/_output/bin/kubectl /out/usr/bin/kubectl

RUN tar -czf /out/cni.tgz -C $GOPATH/github.com/containernetworking/plugins/bin .

RUN cp $GOPATH/bin/crictl /out/usr/bin/crictl
RUN cp $GOPATH/bin/critest /out/usr/bin/critest

RUN cp $GOPATH/src/k8s.io/helm/bin/helm /out/usr/bin/helm

# Remove apk residuals. We have a read-only rootfs, so apk is of no use.
RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache

ADD helm.sh /out/usr/bin/helm.sh
ADD kubelet.sh /out/usr/bin/kubelet.sh
ADD kubeadm.sh /kubeadm.sh
RUN sed -e "s/@KUBERNETES_VERSION@/${kubernetes_version}/g" </kubeadm.sh >/out/usr/bin/kubeadm.sh && chmod +x /out/usr/bin/kubeadm.sh

FROM scratch
WORKDIR /
ENTRYPOINT ["/usr/bin/kubelet.sh"]
COPY --from=build /out /
ENV KUBECONFIG "/etc/kubernetes/admin.conf"
EXPOSE 111/udp 111
