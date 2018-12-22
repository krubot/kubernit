.PHONY: all build vhd pkg

PKG = init containerd runc ca-certificates sysctl sysfs metadata format mount dhcpcd rngd openntpd sshd kubelet getty nfsd

all: base $(PKG) iso

packages: $(PKG) iso

base:
	@make -C tools/alpine build

$(PKG):
	@docker build -t wombat/$@:dev -f pkg/$@/Dockerfile pkg/$@

iso-masters:
	@echo "Wait 10 seconds for linuxkit to become ready"
	@sleep 10
	linuxkit build -format iso-bios kubernit_master0.yaml

iso-nodes:
	@echo "Wait 10 seconds for linuxkit to become ready"
	@sleep 10
	linuxkit build -format iso-bios kubernit_node0.yaml
	linuxkit build -format iso-bios kubernit_node1.yaml

iso-storage:
	@echo "Wait 10 seconds for linuxkit to become ready"
	@sleep 10
	linuxkit build -format iso-bios kubernit_storage0.yaml

iso: iso-masters iso-nodes iso-storage

qemu-masters:
        @echo "Wait 10 seconds for linuxkit to become ready"
        @sleep 10
        linuxkit build -format qcow2-bios kubernit_master0.yaml

qemu-nodes:
        @echo "Wait 10 seconds for linuxkit to become ready"
        @sleep 10
        linuxkit build -format qcow2-bios kubernit_node0.yaml
        linuxkit build -format qcow2-bios kubernit_node1.yaml
 
qemu-storage:
        @echo "Wait 10 seconds for linuxkit to become ready"
        @sleep 10
        linuxkit build -format qcow2-bios kubernit_storage0.yaml
 
qemu: qemu-masters qemu-nodes qemu-storage
