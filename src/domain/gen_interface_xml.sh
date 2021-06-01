# gen_interface_xml testnet 11.22.33.44.55.77 br0
function gen_interface_xml(){
IFMODEL=${IFMODEL:-rtl8139}    #"virtio"
  # $1 network name in NET_MACS, $2 mac address, $3 Bridge name
  #    <target dev='vnet1'/>
  #    <alias name='net0'/>
  str="    <interface type='network'>
      <mac address='$2'/>
      <source network='$1' bridge='$3'/>
      <model type='$IFMODEL'/>
    </interface>"
# declare -p str
echo "$str"
}

# gen_interface_xmls NET_MACS HUB NET_NAMES
function gen_interface_xmls(){
  # $1 net macs map NET_MACS, $2 hostname, $3 network-bridge NET_NAMES
  ret=()
  macs=$(get_host_macs $1 $2)
  IFS=',' maca=($macs); unset IFS
  for i in ${!maca[@]}; do
    vs=${maca[$i]}
    va=($vs)
    # 0 host, 1 index, 2 network, 3 mac
    # echo ${va[1]} ${va[2]}
    BR=$(get_network_brige $3 ${va[2]})
    xml=$(gen_interface_xml ${va[2]} ${va[3]} $BR)
    ret+=("$xml")
  done
  ( IFS=$'\n'; echo "${ret[*]}" )
  # echo "${ret[@]}"
}
