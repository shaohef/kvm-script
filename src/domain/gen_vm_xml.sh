function null_exit(){ [[ -z "$1" ]] && exit 1; }
# BASEIMG=/var/lib/libvirt/images/test.qcow2

# get_vm_xml NET_MACS cloud NET_NAMES
function get_vm_xml(){
# https://stackoverflow.com/questions/9893667/is-there-a-way-to-write-a-bash-function-which-aborts-the-whole-execution-no-mat
trap "exit 1" TERM
export TOP_PID=$$
# kill -s TERM $TOP_PID

echo "BASEIMG=$BASEIMG"
null_exit $BASEIMG
echo "VM_NAME=$VM_NAME"
null_exit $VM_NAME

VM_MEMSIZE_G=${VM_MEMSIZE_G:-10}
VM_VCPUS=${VM_VCPUS:-4}
echo "VM_MEMSIZE_G=$VM_MEMSIZE_G VM_VCPUS=$VM_VCPUS"

IMG=${BASEIMG%/*}/$2.${BASEIMG#*.}
cp $BASEIMG $IMG
virt-edit -a $IMG /etc/hostname -e "s/^.*$/$2/"

ifc=$(virt-ls -a $IMG  /etc/sysconfig/network-scripts/ |grep ifcfg-ens* |head -n 1)
virt-edit -a $IMG /etc/sysconfig/network-scripts/ifc -e 's/^BOOTPROTO=.*/BOOTPROTO=dhcp/'

# $1 net macs map NET_MACS, $2 hostname, $3 network-bridge NET_NAMES
mkdir -p /tmp/vir_domain
INTREFCAE=$(gen_interface_xmls $1 $2 $3)
cat | tee /tmp/vir_domain/${VM_NAME}.xml << EOF
<domain type='kvm' id='2'>
  <name>$VM_NAME</name>
  <memory unit='GiB'>$VM_MEMSIZE_G</memory>
  <vcpu placement='static'>$VM_VCPUS</vcpu>
  <resource>
    <partition>/machine</partition>
  </resource>
  <os>
    <type arch='x86_64' machine='pc-i440fx-rhel7.0.0'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <cpu mode='custom' match='exact' check='full'>
    <model fallback='forbid'>Skylake-Server-IBRS</model>
    <feature policy='require' name='md-clear'/>
    <feature policy='require' name='spec-ctrl'/>
    <feature policy='require' name='ssbd'/>
    <feature policy='require' name='hypervisor'/>
    <feature policy='disable' name='arat'/>
  </cpu>
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <devices>
    <emulator>$KVM</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='$IMG'/>
      <backingStore/>
      <target dev='vda' bus='virtio'/>
      <alias name='virtio-disk0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu'/>
      <target dev='hda' bus='ide'/>
      <readonly/>
      <alias name='ide0-0-0'/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
    <controller type='usb' index='0' model='ich9-ehci1'>
      <alias name='usb'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x7'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci1'>
      <alias name='usb'/>
      <master startport='0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0' multifunction='on'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci2'>
      <alias name='usb'/>
      <master startport='2'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x1'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci3'>
      <alias name='usb'/>
      <master startport='4'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x2'/>
    </controller>
    <controller type='pci' index='0' model='pci-root'>
      <alias name='pci.0'/>
    </controller>
    <controller type='ide' index='0'>
      <alias name='ide'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
    </controller>
$INTREFCAE
    <serial type='pty'>
      <source path='/dev/pts/5'/>
      <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
      </target>
      <alias name='serial0'/>
    </serial>
    <console type='pty' tty='/dev/pts/5'>
      <source path='/dev/pts/5'/>
      <target type='serial' port='0'/>
      <alias name='serial0'/>
    </console>
    <input type='mouse' bus='ps2'>
      <alias name='input0'/>
    </input>
    <input type='keyboard' bus='ps2'>
      <alias name='input1'/>
    </input>
    <video>
      <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
      <alias name='video0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <memballoon model='virtio'>
      <alias name='balloon0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </memballoon>
  </devices>
  <seclabel type='dynamic' model='selinux' relabel='yes'>
    <label>system_u:system_r:svirt_t:s0:c263,c892</label>
    <imagelabel>system_u:object_r:svirt_image_t:s0:c263,c892</imagelabel>
  </seclabel>
  <seclabel type='dynamic' model='dac' relabel='yes'>
    <label>+107:+107</label>
    <imagelabel>+107:+107</imagelabel>
  </seclabel>
</domain>
EOF
}
