#!/bin/bash

# declare -A EDGE1_MACS EDGE2_MACS EDGE3_MACS HUB_MACS CLOUD_MACS

# MACS=(EDGE1_MACS EDGE2_MACS EDGE3_MACS HUB_MACS CLOUD_MACS)
# above 4.3 alpha version support nameref
# declare -A MACS=([EDGE1]="" [EDGE2]="" [EDGE3]="" [HUB]="" [CLOUD]="")

# gen_networt_xmls NET_NAMES NET_MACS 192.168.124.1 nat

# SCRIPT="$(readlink --canonicalize-existing "$0")"
ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for i in `ls ${SCRIPT_DIR}/../src/domain/*`; do
  echo "source $i"
  source $i
done
for i in `ls ${SCRIPT_DIR}/../src/utils/*`; do
  echo "source $i"
  source $i
done

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


# if [[ -z $1 && -z $2 ]] ; then
if [[ -z $1 ]] ; then
   echo "Please specify the domain name and guest user and script files on host, get domain name by:"
   echo "  virsh list --all"
   echo "Usage: "
   # echo "  ${BASH_SOURCE[0]} \$dom \$script \$user"
   exit 1
fi

[[ "running" != "$(virsh domstate $1)" ]] && echo "The vm is not in running" && exit 1

from_beginning=2

# https://unix.stackexchange.com/questions/486657/how-to-get-a-bash-script-argument-given-its-position-from-the-end
xml=$(get_xml $1)
mac=$(gen_dev_index /tmp/vir_domain/tmp.xml) 
host=$(arp |grep $mac |awk '{print $1}')
scp ${SCRIPT_DIR}/../src/vm/script/create_lvm.sh $host:/tmp/
ssh $host -C "/bin/bash /tmp/create_lvm.sh ${@: $from_beginning: 5}"
