#!/bin/sh
set -e
touch /var/lib/kubeadm/.kubeadm-init.sh-started

for opt in $(cat /proc/cmdline); do
	case "$opt" in
	ipAddress=*)
		fullAddress=${opt#ipAddress=}
		ip=${fullAddress%,*}
		;;
	esac
done

if [ -f /etc/kubeadm/kubeadm.yaml ]; then
    echo Using the configuration from /etc/kubeadm/kubeadm.yaml
		if [ "$1" == "init" ]; then
			extraPram=${@#init}
			kubeadm init --config /etc/kubeadm/kubeadm.yaml $extraPram
		elif [ "$1" == "join" ]; then
			extraPram=${@#join}
			kubeadm join --ignore-preflight-errors=all --config /etc/kubeadm/kubeadm.yaml $extraPram
		fi
else
		echo Using the manual configuration
		if [ "$1" == "init" ]; then
			extraPram=${@#init}
    	kubeadm init --ignore-preflight-errors=all --kubernetes-version @KUBERNETES_VERSION@ $extraPram
		elif [ "$1" == "join" ]; then
			extraPram=${@#join}
			kubeadm join --ignore-preflight-errors=all --kubernetes-version @KUBERNETES_VERSION@ $extraPram
		fi
fi

# sorting by basename relies on the dirnames having the same number of directories
NAMESPACES=$(ls -1 /etc/kubeadm/kube-system.init/*.yaml 2>/dev/null | sort --field-separator=/ --key=5 | sed 's|.*/||')
for namespace in ${NAMESPACES}; do
		YAML=$(ls -1 /etc/kubeadm/kube-system.init/"$namespace"/*.yaml 2>/dev/null | sort --field-separator=/ --key=5)
    n=$(basename "$i")
    if [ -e "$i" ] ; then
			if [ ! -s "$i" ] ; then # ignore zero sized files
	    	echo "Ignoring zero size file $n"
	    	continue
			fi
			echo "Applying $n"
			if ! kubectl create -n kube-system -f "$i" ; then
	    	touch /var/lib/kubeadm/.kubeadm-init.sh-kube-system.init-failed
	    	touch /var/lib/kubeadm/.kubeadm-init.sh-kube-system.init-"$n"-failed
	    	echo "Failed to apply $n"
	    	continue
			fi
    fi
done
if [ -f /run/config/kubeadm/untaint-master ] ; then
    echo "Removing \"node-role.kubernetes.io/master\" taint from all nodes"
    kubectl taint nodes --all node-role.kubernetes.io/master-
fi
touch /var/lib/kubeadm/.kubeadm-init.sh-finished
