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
    tar -xzf /root/cni.tgz -C /var/lib/cni/bin
    touch /var/lib/cni/.opt.defaults-extracted
fi

if [ ! -e /var/lib/cni/.cni.conf-extracted ] && [ -d /run/config/cni ] ; then
    mkdir -p /var/lib/cni/conf
    cp /run/config/cni/* /var/lib/cni/conf/
    touch /var/lib/cni/.cni.configs-extracted
fi

# NFS client setup
mount -t nfsd nfsd /proc/fs/nfsd

echo 'starting rpcbind...'
/sbin/rpcbind -w
echo "Displaying rpcbind status..."
/sbin/rpcinfo
/sbin/rpc.statd

echo "Starting NFS in the background..."
/usr/sbin/rpc.nfsd --debug 8 --no-udp --no-nfs-version 2

echo "Starting Mountd in the background..."
/usr/sbin/rpc.mountd --debug all --no-udp --no-nfs-version 2

await=/etc/kubernetes/kubelet.conf

if [ -f "/etc/kubernetes/kubelet.conf" ] ; then
    echo "kubelet.sh: kubelet already configured"
elif [ -d /etc/kubeadm ] ; then
    if [ -f /etc/kubeadm/init ] ; then
	     echo "kubelet.sh: init cluster with metadata \"$(cat /etc/kubeadm/init)\""
	     kubeadm.sh init --skip-token-print $(cat /etc/kubeadm/init) &
    elif [ -f /etc/kubeadm/join ] ; then
	     echo "kubelet.sh: joining cluster with metadata \"$(cat /etc/kubeadm/join)\""
       kubeadm.sh join $(cat /etc/kubeadm/init)
	     await=/etc/kubernetes/bootstrap-kubelet.conf
    fi
fi

echo "kubelet.sh: waiting for ${await}"

until [ -f "${await}" ] ; do
    sleep 1
done

echo "kubelet.sh: ${await} has arrived" 2>&1

mkdir -p /etc/kubernetes/manifests

exec kubelet --kubeconfig=/etc/kubernetes/kubelet.conf \
	      --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf \
	      --pod-manifest-path=/etc/kubernetes/manifests \
	      --allow-privileged=true \
	      --cluster-dns=10.200.0.10 \
	      --cluster-domain=cluster.local \
	      --cgroups-per-qos=false \
	      --enforce-node-allocatable= \
	      --network-plugin=cni \
	      --cni-conf-dir=/etc/cni/net.d \
	      --cni-bin-dir=/opt/cni/bin \
	      --cadvisor-port=0 \
	      --kube-reserved-cgroup=podruntime \
	      --system-reserved-cgroup=systemreserved \
	      --cgroup-root=kubepods \
        --container-runtime=remote \
        --container-runtime-endpoint=unix:///run/containerd/containerd.sock \
	      $KUBELET_ARGS $@
