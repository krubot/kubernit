#!/bin/sh

set -eu

function stop() {
    echo "Stopping NFS"

    /usr/sbin/rpc.nfsd 0
    /usr/sbin/exportfs -au
    /usr/sbin/exportfs -f

    kill $( pidof rpc.mountd )
    umount /proc/fs/nfsd
    echo > /etc/exports
    exit 0
}

trap stop TERM

mount -t nfsd nfsd /proc/fs/nfsd

echo 'starting rpcbind...'
/sbin/rpcbind -w
echo "Displaying rpcbind status..."
/sbin/rpcinfo
/sbin/rpc.statd

echo "Starting NFS in the background..."
/usr/sbin/rpc.nfsd --debug 8 --no-udp --no-nfs-version 2

echo "Exporting File System..."
/usr/sbin/exportfs -rv
/usr/sbin/exportfs

echo "Starting Mountd in the background..."
/usr/sbin/rpc.mountd --debug all --no-udp --no-nfs-version 2 --foreground
