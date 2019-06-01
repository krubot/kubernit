#!/bin/sh
# Kubelet outputs only to stderr, so arrange for everything we do to go there too
exec 1>&2

if [ -e /etc/kubelet.sh.conf ] ; then
    . /etc/kubelet.sh.conf
fi

if [ -f /run/config/kubelet/disabled ] ; then
    echo "kubelet.sh: /run/config/kubelet/disabled file is present, exiting"
    exit 0
fi

if [ -n "$KUBELET_DISABLED" ] ; then
    echo "kubelet.sh: KUBELET_DISABLED environ variable is set, exiting"
    exit 0
fi

if [ ! -e /var/lib/cni/.opt.defaults-extracted ] ; then
    mkdir -p /var/lib/cni/bin
    tar -xzf /cni.tgz -C /var/lib/cni/bin
    touch /var/lib/cni/.opt.defaults-extracted
fi

if [ ! -e /var/lib/cni/.cni.conf-extracted ] && [ -d /run/config/cni ] ; then
    mkdir -p /var/lib/cni/conf
    cp /run/config/cni/* /var/lib/cni/conf/
    touch /var/lib/cni/.cni.configs-extracted
fi

await=/etc/kubernetes/kubelet.conf

if [ -f "/etc/kubernetes/kubelet.conf" ] ; then
    echo "kubelet.sh: kubelet already configured"
elif [ -d /etc/kubeadm ] ; then
    if [ -f /etc/kubeadm/init ] ; then
	     echo "kubelet.sh: init cluster with metadata \"$(cat /etc/kubeadm/init)\""
	     kubeadm.sh init --skip-token-print $(cat /etc/kubeadm/init) &
    elif [ -f /etc/kubeadm/join ] ; then
	     echo "kubelet.sh: joining cluster with metadata \"$(cat /etc/kubeadm/join)\""
       kubeadm.sh join $(cat /etc/kubeadm/join)
	     await=/etc/kubernetes/bootstrap-kubelet.conf
    fi
fi

echo "kubelet.sh: waiting for ${await}"

until [ -f "${await}" ] ; do
    sleep 1
done

echo "kubelet.sh: ${await} has arrived" 2>&1

if [ -f "/run/config/kubelet-config.json" ]; then
    echo "Found kubelet configuration from /run/config/kubelet-config.json"
else
    echo "Generate kubelet configuration to /run/config/kubelet-config.json"
    : ${KUBE_CLUSTER_DNS:='"10.200.0.10"'}
    cat > /run/config/kubelet-config.json << EOF
    {
        "kind": "KubeletConfiguration",
        "apiVersion": "kubelet.config.k8s.io/v1beta1",
        "staticPodPath": "/etc/kubernetes/manifests",
        "clusterDNS": [
            ${KUBE_CLUSTER_DNS}
        ],
        "clusterDomain": "cluster.local",
        "cgroupsPerQOS": false,
        "enforceNodeAllocatable": [],
        "kubeReservedCgroup": "podruntime",
        "systemReservedCgroup": "systemreserved",
        "cgroupRoot": "kubepods"
    }
EOF
fi

mkdir -p /etc/kubernetes/manifests

# If using --cgroups-per-qos then need to use --cgroup-root=/ and not
# the --cgroup-root=kubepods from below. This can be done at image
# build time by adding to the service definition:
#
#    command:
#      - /usr/bin/kubelet.sh
#      - --cgroup-root=/
#      - --cgroups-per-qos
exec kubelet \
          --config=/run/config/kubelet-config.json \
          --kubeconfig=/etc/kubernetes/kubelet.conf \
          --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf \
          --network-plugin=cni \
          --cni-conf-dir=/etc/cni/net.d \
          --cni-bin-dir=/opt/cni/bin \
          --container-runtime=remote \
          --container-runtime-endpoint=unix:///run/containerd/containerd.sock \
          $KUBELET_ARGS $@
