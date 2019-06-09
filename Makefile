.PHONY: all build vhd pkg

PKG = init containerd runc ca-certificates sysctl sysfs metadata format mount dhcpcd rngd openntpd sshd kubelet getty nfsd what

all: base $(PKG) iso

packages: $(PKG) iso

base:
	@make -C tools/alpine build

$(PKG):
	@docker build -t kubernit/$@:dev -f pkg/$@/Dockerfile pkg/$@

masters:
	@echo "Wait 10 seconds for linuxkit to become ready"
	@sleep 10
	linuxkit build kubernit_master0.yaml

workers:
	@echo "Wait 10 seconds for linuxkit to become ready"
	@sleep 10
	linuxkit build kubernit_worker0.yaml
	linuxkit build kubernit_worker1.yaml

storage:
	@echo "Wait 10 seconds for linuxkit to become ready"
	@sleep 10
	linuxkit build kubernit_storage0.yaml

kernel: masters workers storage

iso-masters:
	@echo "Wait 10 seconds for linuxkit to become ready"
	@sleep 10
	linuxkit build -format iso-bios kubernit_master0.yaml

iso-workers:
	@echo "Wait 10 seconds for linuxkit to become ready"
	@sleep 10
	linuxkit build -format iso-bios kubernit_worker0.yaml
	linuxkit build -format iso-bios kubernit_worker1.yaml

iso-storage:
	@echo "Wait 10 seconds for linuxkit to become ready"
	@sleep 10
	linuxkit build -format iso-bios kubernit_storage0.yaml

iso-wireguard:
	@echo "Wait 10 seconds for linuxkit to become ready"
	@sleep 10
	linuxkit build -format iso-bios kubernit_wireguard0.yaml

iso: iso-masters iso-workers iso-storage

qemu-masters:
	@echo "Wait 10 seconds for linuxkit to become ready"
	@sleep 10
	linuxkit build -format qcow2-bios kubernit_master0.yaml

qemu-workers:
	@echo "Wait 10 seconds for linuxkit to become ready"
	@sleep 10
	linuxkit build -format qcow2-bios kubernit_worker0.yaml
	linuxkit build -format qcow2-bios kubernit_worker1.yaml

qemu-storage:
	@echo "Wait 10 seconds for linuxkit to become ready"
	@sleep 10
	linuxkit build -format qcow2-bios kubernit_storage0.yaml

qemu: qemu-masters qemu-workers qemu-storage
