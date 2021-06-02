#!/bin/bash

# declare -A EDGE1_MACS EDGE2_MACS EDGE3_MACS HUB_MACS CLOUD_MACS

# MACS=(EDGE1_MACS EDGE2_MACS EDGE3_MACS HUB_MACS CLOUD_MACS)
# above 4.3 alpha version support nameref
# declare -A MACS=([EDGE1]="" [EDGE2]="" [EDGE3]="" [HUB]="" [CLOUD]="")

# gen_networt_xmls NET_NAMES NET_MACS 192.168.124.1 nat

# HOST=${HOST} BASEIMG=${BASEIMG} VM_NAME=${VM_NAME} VM_MEMSIZE_G=$VM_MEMSIZE_G VM_VCPUS=$VM_VCPUS 

# SCRIPT="$(readlink --canonicalize-existing "$0")"
ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source ${SCRIPT_DIR}/../global.vars
for i in `ls ${SCRIPT_DIR}/../src/utils/*`; do
  echo "source $i"
  source $i
done

for i in `ls ${SCRIPT_DIR}/../src/domain/*`; do
  echo "source $i"
  source $i
done


# echo $ABSOLUTE_PATH, $SCRIPT_NAME, $SCRIPT_DIR

if [[ -z $1 && -z $2 ]] ; then
   echo "Please define MACS, NET_NAMES, NET_MACS, as follow example:"
   echo "---------------- global vars define ----------------"
   cat ${SCRIPT_DIR}/../global.vars
   echo "---------------- define end ----------------"
   echo 'EDGE1, EDGE2, EDGE3, HUB, CLOUD are hostname.'
   echo "see define in: global.vars"
   echo ""
   echo "---------------- domain vars define ----------------"
   echo "  export HOST=cloud"
   echo "  export BASEIMG=/var/lib/libvirt/images/test.qcow2"
   echo ""
   echo "  export VM_NAME=smartcity_\$HOST"
   echo "  export VM_MEMSIZE_G=10"
   echo "  export VM_VCPUS=6"
   echo "---------------- define end ----------------"
   echo ""
   echo "Usage: "
   echo "  ${BASH_SOURCE[0]} NET_MACS \$HOST NET_NAMES"
   echo "Check result by:"
   echo "  ls /tmp/vir_domain/\${VM_NAME}.xml"
   exit 1
fi

# https://stackoverflow.com/questions/4824590/propagate-all-arguments-in-a-bash-shell-script
# echo $@, $*, "$@", "$*"
get_vm_xml $@ 
echo "  ls /tmp/vir_domain/${VM_NAME}.xml"
