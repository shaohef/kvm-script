# network_struct_parser 'ansible_edge: asedgebr0,nat ' 2
# network_struct_parser 'ansible_edge: asedgebr0' mode
function network_struct_parser(){
  # $1 struct string, $2 index(0,1,2,3) or key(net/br/mode/cidr)
  IFS=',: ' array=($1) ; unset IFS
  array[2]=${array[2]:-nat}
  declare -A MAP
  MAP=([net]=0 [br]=1 [mode]=2 [cidr]=3)
  # if [ -I "$2" ] ;
  [[ $2 =~ ^-?[0-9]+$ ]] && i=$2 || i=${MAP[$2]}
  echo ${array[$i]}
}

# network_struct_key 'ansible_edge: asedgebr0,nat '
function network_struct_key(){
  # $1 struct string
  echo ${1%:*}
}

# get_network_struct_item NET_NAMES ansible_cloud
function get_network_struct_item(){
# $1 NET_NAMES $2 key(network name)
for i in $(eval "echo \${!$1[@]}"); do
  v=$(eval "echo \${$1[i]}")
  NM=${v%:*}    BR=${v#*:}
  if [ "$NM" = "$2" ]; then
    echo $v
    break
  fi
done
}

# get_network_struct_value NET_NAMES ansible_cloud
function get_network_struct_value(){
# $1 NET_NAMES $2 key(network name)
for i in $(eval "echo \${!$1[@]}"); do
  v=$(eval "echo \${$1[i]}")
  NM=${v%:*}    VAL=${v#*:}
  if [ "$NM" = "$2" ]; then
    echo $VAL
    break
  fi
done
}

# grep_ip 'ansible_edge: asedgebr0,nat,192.168.1.1' cidr
function grep_ip(){
  match=$(grep -o '[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}' <<< $1)
  if [ $? -eq 0 ]; then
    echo $match
  fi
}

# network_struct_get_ip 'ansible_edge: asedgebr0,nat,192.168.1.1'
# network_struct_get_ip 'ansible_edge: asedgebr0,'
# network_struct_get_ip 'ansible_edge: asedgebr0,192.168.1.1'
function network_struct_get_ip(){
  # echo $(network_struct_parser "$1" mode)
  possible=$(grep_ip $(network_struct_parser "$1" mode))
  ip=${possible:-$(network_struct_parser "$1" cidr)}
  ip=$(grep_ip "$ip")
  echo $ip
}

# network_struct_get_mode 'ansible_edge: asedgebr0,nat,192.168.1.1'
# network_struct_get_mode 'ansible_edge: asedgebr0,'
# network_struct_get_mode 'ansible_edge: asedgebr0,192.168.1.1,nat'
# network_struct_get_mode 'ansible_edge: asedgebr0,192.168.1.1'
function network_struct_get_mode(){
  mode=$(network_struct_parser "$1" mode)
  possible=$(grep_ip $mode)
  [[ ! -z "$possible" ]] && mode=$(network_struct_parser "$1" cidr)
  mode=${mode:-nat}
  echo $mode
}
