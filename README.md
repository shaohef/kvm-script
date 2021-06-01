# kvm-script
tools to management KVM

## Generate a mac pool for host interfaces

```
./cmd/generate_mac_pool.sh

declare -A MACS=([host1]="" [host2]="" [hostn]="")
./cmd/generate_mac_pool.sh
```

## Generate network xml snippet files and create network

```
./cmd/generate_network_xmls.sh

./cmd/generate_network_xmls.sh NET_NAMES NET_MACS
ls /tmp/vir_network
virsh net-create /tmp/vir_network
virsh net-list

```
delete a network by: `virsh net-destroy`
