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


# echo $ABSOLUTE_PATH, $SCRIPT_NAME, $SCRIPT_DIR

if [[ -z $1 && -z $2 ]] ; then
   echo "Please define MACS, NET_NAMES, NET_MACS, as follow example:"
   echo "---------------- global vars define ----------------"
   cat ${SCRIPT_DIR}/../src/global.vars
   echo "---------------- define end ----------------"
   echo 'EDGE1, EDGE2, EDGE3, HUB, CLOUD are hostname.'
   echo "see define in: src/global.vars"
   echo ""
   echo "---------------- domain vars define ----------------"
   echo "  HOST=cloud"
   echo "  IMG=/var/lib/libvirt/images/\$HOST.qcow2"
   echo ""
   echo "  VM_NAME=smartcity_\$HOST"
   echo "  VM_MEMSIZE_G=10"
   echo "  VM_VCPUS=6"
   echo "---------------- define end ----------------"
   echo ""
   echo "Usage: "
   echo "  ${BASH_SOURCE[0]} get_vm_xml NET_MACS \$HOST NET_NAMES"
   exit 1
fi

# https://stackoverflow.com/questions/4824590/propagate-all-arguments-in-a-bash-shell-script
# echo $@, $*, "$@", "$*"
get_vm_xml NET_MACS $HOST NET_NAMES
