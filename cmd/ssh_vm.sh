#!/bin/bash

# declare -A EDGE1_MACS EDGE2_MACS EDGE3_MACS HUB_MACS CLOUD_MACS

# MACS=(EDGE1_MACS EDGE2_MACS EDGE3_MACS HUB_MACS CLOUD_MACS)
# above 4.3 alpha version support nameref
# declare -A MACS=([EDGE1]="" [EDGE2]="" [EDGE3]="" [HUB]="" [CLOUD]="")

# gen_networt_xmls NET_NAMES NET_MACS 192.168.124.1 nat

# SCRIPT="$(readlink --canonicalize-existing "$0")"
# ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
# SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# for i in `ls ${SCRIPT_DIR}/../src/domain/*`; do
#   echo "source $i"
#   source $i
# done
# for i in `ls ${SCRIPT_DIR}/../src/utils/*`; do
#   echo "source $i"
#   source $i
# done

# echo $ABSOLUTE_PATH, $SCRIPT_NAME, $SCRIPT_DIR


function get_xml(){
  xml=/tmp/vir_domain/tmp.xml
  mkdir -p /tmp/vir_domain
  virsh dumpxml $1 > $xml
  # if [[ $? -ne 0 ]] ; then
  #   echo "Please input a validate domain name."
  #   exit 1
  # fi
  echo $xml
}


# get_xml_attr_value $XML_IFC_EXP smartcity_cloud.xml
function get_xml_attr_value(){
ret=()
str=$(xmllint --xpath "$1" $2)
entries=($(echo ${str}))
for entry in "${entries[@]}"; do
  result=$(echo $entry | awk -F'[="]' '!/>/{print $(NF-1)}')
  ret+=("$result")
done
echo ${ret[@]}
}


function get_dom_xml_attr_value(){
ret=()
str=$(virsh dumpxml $2 |xmllint --xpath "$1" -)
entries=($(echo ${str}))
for entry in "${entries[@]}"; do
  result=$(echo $entry | awk -F'[="]' '!/>/{print $(NF-1)}')
  ret+=("$result")
done
echo ${ret[@]}
}


function gen_dev_index(){
  xml=$1
  XML_IFC_EXP="//*[local-name()='interface'][1][@type='network']/mac/@address"
  # jq '.[2:4]' <<< '["vda","vdb","vdc","vdd","vde"]'
  # jq '.[0:1]' <<< "[\"vda\",\"vdb\"]"
  # Advanced Bash-Scripting Guide: Chapter 27. Arrays
  # https://tldp.org/LDP/abs/html/arrays.html
  macs=$(get_xml_attr_value $XML_IFC_EXP $xml)
  echo $macs
  # last=$(jq 'sort_by(.)|.[-1]' <<< $(str2jsonlist $disks))
}

function get_ip_from_file(){
  statf=`grep $1 /var/lib/libvirt/dnsmasq/*.status |awk -F"[, :]" '{print $1}'`
  idx=`jq ". |map(.\"mac-address\" == \"$1\") |index(true)" $statf`
  ip=`jq ".[$idx].\"ip-address\"" $statf`
  echo ${ip//\"/}
}

function get_ip_from_virsh(){
  XML_MAC_EXP="//*[local-name()='interface'][1][@type='network']/mac/@address"
  XML_NET_EXP="//*[local-name()='interface'][1][@type='network']/source/@network"
  net=$(get_dom_xml_attr_value $XML_NET_EXP $1) 
  mac=$(get_dom_xml_attr_value $XML_MAC_EXP $1) 
  ip=`virsh net-dhcp-leases $net $mac |grep -v "Expiry Time" |grep -v "^---" |grep -v "^$" |awk '{print $5}'`
  echo ${ip%%/*}
}

if [[ -z $1 ]] ; then
   echo "Please specify the domain name and guest user, get domain name by:"
   echo "  virsh list --all"
   virsh list
   echo "Usage: "
   echo "  ${BASH_SOURCE[0]} [\$user@]\$dom"
   exit 1
fi

[[ "running" != "$(virsh domstate $1)" ]] && echo "The vm is not in running" && exit 1

dom=${1#*@}
[[ $1 =~ "@" ]] && user_at="${1%%@*}@" || user_at=""

# host=$(get_ip_from_virsh $dom)
# https://unix.stackexchange.com/questions/486657/how-to-get-a-bash-script-argument-given-its-position-from-the-end
xml=$(get_xml $dom)
mac=$(gen_dev_index /tmp/vir_domain/tmp.xml)
# host=$(arp |grep $mac |awk '{print $1}')
host=$(get_ip_from_file $mac)

ssh ${user_at}$host
