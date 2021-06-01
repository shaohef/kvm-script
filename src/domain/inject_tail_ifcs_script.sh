NIC_PREFIX=ens 
virsh list --all

# inject_ifc_script smartcity_edge3 
function inject_ifc_script(){
# $1 domain name
[[ "running" == "$(virsh domstate $1)" ]] && echo "The vm in running, exit" && return 1
mkdir -p /tmp/vir_domain
virsh dumpxml $1 > /tmp/vir_domain/vm_tmp.xml

NIC_PREFIX=${NIC_PREFIX:-ens}
XML_IFC_EXP_DEF="//*[local-name()='interface']/address/@slot"
XML_IFC_EXP=${XML_IFC_EXP:-$XML_IFC_EXP_DEF}
dev=$(get_xml_attr_value $XML_IFC_EXP /tmp/vir_domain/vm_tmp.xml)
build_list=($dev)

for i in "${build_list[@]:1}"; do
   ifc="${NIC_PREFIX}${i#0x0*}"
   gen_ifcfg $ifc
   virt-copy-in -d $1 /tmp/vir_domain/ifcfg-$ifc /etc/sysconfig/network-scripts
done
}

function gen_ifcfg(){
BOOTPROTO=${BOOTPROTO:-none}
cat > /tmp/vir_domain/ifcfg-$1 << EOF
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=${BOOTPROTO}
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=$1
# UUID=ccf2fab2-87aa-4279-b7dc-e8f3f2b87d12
DEVICE=$1
ONBOOT=yes
# IPADDR=192.168.122.3
# NETMASK=255.255.255.0
# GATEWAY=192.168.122.1
EOF
}
