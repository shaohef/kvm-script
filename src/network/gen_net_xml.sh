# gen_networt_xml ansible_edge asedgebr0 192.168.124.1 $dhcp nat 
function gen_networt_xml(){
# $1 NET_NAME $2 BR NAME $3 IP $4 DHCP $5 MODE
str="<network>
  <name>$1</name>
  <bridge name=\"$2\"/>
  <forward mode=\"${5}\"/>
  <ip address=\"${3%.*}.1\" netmask=\"255.255.255.0\">
    <dhcp>
      <range start=\"${3%.*}.2\" end=\"${3%.*}.192\"/>
$4
    </dhcp>
  </ip>
</network>"

[[ ! -z ${5} && "isolated" =~ ${5,,} ]] && mode= || mode="  <forward mode=\"${5}\"/>"

mkdir -p /tmp/vir_network
cat | tee /tmp/vir_network/$1.xml << EOF
<network>
  <name>$1</name>
  <bridge name="$2"/>
$mode
  <ip address="${3%.*}.1" netmask="255.255.255.0">
    <dhcp>
      <range start="${3%.*}.2" end="${3%.*}.192"/>
$4
    </dhcp>
  </ip>
</network>
EOF
# declare -p str
}


# gen_networt_xmls NET_NAMES NET_MACS 192.168.124.1 nat 
# gen_networt_xmls NET_NAMES NET_MACS 
function gen_networt_xmls(){
# $1 NET_NAMES $2 NET_MACS $3 IP $4 MODE: nat or route
IP=${3:-192.168.124.2}
for i in $(eval "echo \${!$1[@]}"); do
  v=$(eval "echo \${$1[i]}")
  NM=${v%:*}    BR=$(network_struct_parser "$v" br)
  ip=$(inc_subnet $IP $i)
  cidr_ip=$(network_struct_get_ip "$v")
  ip=${cidr_ip:-$ip}
  dhcp=$(gen_dhcp_items $2 $NM $ip)
  mode=$(network_struct_get_mode "$v")
  gen_networt_xml $NM $BR $ip "$dhcp" ${4:-$mode}
done
}
