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

# https://unix.stackexchange.com/questions/144298/delete-the-last-character-of-a-string-using-string-manipulation-in-shell-script
function get_next_disk_index(){
  last=$1
  last=${last#\"}; last=${last%\"}
  echo ${last%?}$(tr 'a-zA-Z' 'b-zA-Za' <<< ${last: -1})
}


function get_xml(){
  xml=/tmp/vir_domain/tmp.xml
  mkdir -p /tmp/vir_domain
  virsh dumpxml $1 > $xml
  echo $xml
}

function gen_dev_index(){
  xml=$1
  # XML_IFC_EXP="//*[local-name()='disk'][2][@device='disk']/target/@dev"
  XML_IFC_EXP="//*[local-name()='disk'][@device='disk']/target/@dev"
  # jq '.[2:4]' <<< '["vda","vdb","vdc","vdd","vde"]'
  # jq '.[0:1]' <<< "[\"vda\",\"vdb\"]"
  # Advanced Bash-Scripting Guide: Chapter 27. Arrays
  # https://tldp.org/LDP/abs/html/arrays.html
  disks=$(get_xml_attr_value $XML_IFC_EXP $xml)
  last=$(jq 'sort_by(.)|.[-1]' <<< $(str2jsonlist $disks))
  get_next_disk_index $last
}


function get_blks(){
  index=0
  ret=()
  for i in $(virsh domblklist $1 | grep -v "^Target" |grep -v "^-" |grep -v " -" |grep -v "^$"|sort);
  do
     remainder=$(( $index % 2 ))
     if [ $remainder -ne 0 ]
     then
       ret+=("${i}",)
     else
       ret+=("${i}":)
     fi
     index=$(($index+1))
  done
  echo ${ret[@]}
}


function gen_last_blk_dev(){
  # last=$(jq 'sort_by(.)|.[-1]' <<< $(str2jsonlist "$blks"))
  # IFS=$'\n ' array=(${blks//[[:space:]]/}) ; unset IFS
  blks=$(get_blks $1)
  IFS=',' array=(${blks//[[:space:]]/}) ; unset IFS
  # echo ${blks[-1]}  # Bash 4.2 - 4.3
  first=${array[0]}
  # len=${#array[@]}
  # last=${array[$(($len- 1))]}
  last=${array[${#array[@]}-1]}
  get_next_disk_index ${last%%:*}
}

function gen_last_blk_img(){
  blks=$(get_blks $1)
  # last=$(jq 'sort_by(.)|.[-1]' <<< $(str2jsonlist "$blks"))
  # IFS=$'\n ' array=(${blks//[[:space:]]/}) ; unset IFS
  IFS=',' array=(${blks//[[:space:]]/}) ; unset IFS
  # echo ${blks[-1]}  # Bash 4.2 - 4.3
  first=${array[0]}
  last=${array[${#array[@]}-1]}
  # echo ${first##*:}, ${last%%:*}
  img=${first##*:}
  echo $img
}

function gen_image_name(){
  xml=$1
  XML_IFC_EXP="//*[local-name()='disk'][@device='disk']/source/@file"
  imgs=$(get_xml_attr_value $XML_IFC_EXP $xml)
  img=$(cut -d " " -f 1 <<< $imgs)
  img=${img%.*}_${2}.${img#*.}
  echo $img
}

# https://serverfault.com/questions/457250/kvm-and-libvirt-how-do-i-hotplug-a-new-virtio-disk
function attach_disk(){
  dom=$1
  xml=$(get_xml $1)
  # echo $xml
  # dev=${3:-$(gen_dev_index $xml)}

  # blks=$(get_blks $1)
  dev=$(gen_last_blk_dev $dom)
  # echo $dev
  img=$(gen_last_blk_img $dom $dev)
  img=${img%.*}_${dev}.${img#*.}
  # img=$(gen_image_name $xml $dev)
  echo "attach $img as $dev"
  qemu-img create -f qcow2 $img $2
  # virt-format -a $img
  virt-filesystems --long -h --all -a $img
  virsh attach-disk $1 $img $dev --driver=qemu --subdriver=qcow2 --current # --persistent --live --config
}

if [[ -z $1 && -z $2 ]] ; then
   echo "Please specify the domain name and disk size, get domain name by:"
   echo "  virsh list --all"
   echo "Usage: "
   echo "  ${BASH_SOURCE[0]} \$dom \$size "
   echo "This command just format disk, not format lvm, we can enhance it later"
   exit 1
fi

# https://stackoverflow.com/questions/4824590/propagate-all-arguments-in-a-bash-shell-script
# echo $@, $*, "$@", "$*"

attach_disk $@
echo "detach a disk: "
echo "  virsh detach-disk $1 \$dev  # --persistent --live --current --config"
echo "login vm and run:"
echo "  modprobe acpiphp"
echo "  modprobe pci_hotplug"
echo "  dmesg |grep virtio-pci"
