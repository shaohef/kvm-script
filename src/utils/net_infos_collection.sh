# declare -p NET_MACS
# get_net_macs NET_MACS ansible_edge
function get_net_macs(){
  # $1 net macs map NET_MACS, $2 net mames, $3 macs pool
  mac_idxs=$(eval "echo \${$1[$2]}") 
  # IFS=', ' read -r -a array <<< "$string" 
  # array=(${string//:/ }) 
  macstr=($mac_idxs)
  # return value
  ret=()
  for v in "${macstr[@]}"; do
    host=${v%%:*}     idx=${v##*:}    macs=${v%%:*}_MACS
    string=$(eval "echo \${$macs}")
    # IFS=', ' array=($countries)
    array=($string)
    # echo "\${array[${!idx}]}"
    mac=$(eval "echo \${array[${idx}]}")
    ret+=($mac)
  done
  echo ${ret[@]}
}


# gen_host_array NET_MACS ansible_edge 
function gen_host_array(){
  # $1 net macs map NET_MACS, $2 net mames, $3 base ip addr
  mac_idxs=$(eval "echo \${$1[$2]}") 
  HOST=${mac_idxs//:/.}
  echo ${HOST,,}
}

# inc_subnet 192.168.124.1 3
function inc_subnet(){
  SUBN=${1#*.*.}
  SUBN=${SUBN%.*}
  SUFFIX=${1##*.}
  echo ${1%.*.*}.$((${SUBN} + ${2})).${SUFFIX}
}

# inc_ipaddr 192.168.124.1 3
function inc_ipaddr(){
  echo ${1%.*}.$((${1##*.} + $2))
}

# gen_ip_array NET_MACS smartcity_edge 192.168.127.1
function gen_ip_array(){
  # $1 net macs map NET_MACS, $2 net mames, $3 base ip addr
  mac_idxs=$(eval "echo \${$1[$2]}") 
  macstr=($mac_idxs)
  len=${#macstr[@]}
  ret=()
  for (( i=0; i<$len; i++ )); do
    ip=$(inc_ipaddr $3 $i); 
    ret+=($ip)
  done
  echo ${ret[@]}
}

# get_host_macs NET_MACS HUB
function get_host_macs(){
  # $1 net macs map NET_MACS, $2 hostname, $3 macs pool
  VAL=${2^^}
  ret=()
  for i in $(eval "echo \${!$1[@]}"); do
    v=$(eval "echo \${$1[$i]}")
    match=$(grep -o "$VAL:[[:digit:]]\{1,4\}" <<< $v)
    if [ $? -ne 0 ]; then
      continue
    fi
    idx=${match#*:}
    macs=${match%%:*}_MACS
    string=$(eval "echo \${$macs}")
    array=($string)
    # echo "\${array[${!idx}]}"
    mac=$(eval "echo \${array[${idx}]}")
    # 0 host, 1 index, 2 network, 3 mac
    ret+=("$VAL $idx $i $mac,")
  done
  # IFS=$'\n' sorted=($(sort <<<"${ret[*]}")); unset IFS
  # readarray -t sorted < <(for a in "${ret[@]}"; do echo "$a"; done | sort)
  sorted=($(printf '%s\n' "${ret[@]}"|sort))
  echo ${sorted[@]}
}

# get_network_brige NET_NAMES ansible_cloud
function get_network_brige(){
# $1 NET_NAMES $2 network name
for i in $(eval "echo \${!$1[@]}"); do
  v=$(eval "echo \${$1[i]}")
  NM=${v%:*}    BR=$(awk -F"[, :]" '{print $1}' <<< ${v#*: })
  if [ "$NM" = "$2" ]; then
    echo $BR
    break
  fi
done
}
