function get_dhcp_item(){
  # $1 MAC, $2 HOST, $3 DOMAIN, $4 IP
  DOM=${3/_/.}
  # (IFS=$';';  echo "      <host mac=\"$1\" name=\"${2,,}.${DOM,,}.com\" ip=\"$4\"/>")
  echo "      <host mac=\"$1\" name=\"${2,,}.${DOM,,}.com\" ip=\"$4\"/>"
}

# gen_dhcp_items NET_MACS ansible_edge 192.168.124.192
function gen_dhcp_items(){
  # $1 net macs map NET_MACS, $2 net mames, $3 base ip addr
  hosts=$(gen_host_array $1 $2)  
  macs=$(get_net_macs $1 $2)
  ips=$(gen_ip_array $1 $2 $3)
  ha=($hosts)   hm=($macs)  hi=($ips)
  ret=()
  for i in ${!ha[@]}; do
    itm=$(get_dhcp_item ${hm[$i]} ${ha[$i]} $2 ${hi[$i]})
    # declare -p itm
    ret+=("$itm")
    # echo ${ha[$i]} ${hm[$i]} ${hi[$i]}
  done
  # echo ${ret[@]}
  # declare -p ret
  ( IFS=$'\n'; echo "${ret[*]}" )
}
