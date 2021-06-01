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

## Generate domain xml snippet files and create vm

```
./cmd/generate_domain_xml.sh

HOST=cloud
IMG=/var/lib/libvirt/images/$HOST.qcow2

VM_NAME=smartcity_$HOST
VM_MEMSIZE_G=10
VM_VCPUS=6

./cmd/generate_domain_xml.sh NET_MACS $HOST NET_NAMES
virsh create /tmp/vir_domain/$VM_NAME.xml
virsh list
```

## inject interface script to disable dhcp

```
./cmd/inject_tail_ifcs_script.sh
./cmd/inject_tail_ifcs_script.sh $dom
```

## set hostname for domain
```
./cmd/set_hostname.sh
./cmd/set_hostname.sh $dom $hostname
```

## set hostname for domain
```
./cmd/inject_ssh_key.sh
./cmd/inject_ssh_key.sh $dom $user $key_file
```
