# kubernit

Currently still in working progress, long term plan is to integrate it with libvirt to generate virtual machines for each node in the cluster.

## Building with virtualbox

Build the iso by running:

```
make all
```

Build a new vm in virtualbox with type `Linux` and version `Linux 2.6 / 3.x / 4.x (64 bit)`. Extend the memory size to about `8192MB` and add a `8GB` disk. Before running attach the iso and add the hostonly network we created at the start and a `network nat` on the the second adapter. Now you can start the VM.

Once the node has fully booted ssh to it by running `ssh_into_kubelet` script with the ip. Therefore in this example:

```
./ssh_into_kubelet.sh 192.168.58.10
```
