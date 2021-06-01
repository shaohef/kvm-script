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

function set_hostname() {
# $1 domain name $2 host name
[[ "running" == "$(virsh domstate $1)" ]] && echo "The vm in running, exit" && return 1
virt-edit -d $1 /etc/hostname -e "s/^.*$/$2/"
}

# echo $ABSOLUTE_PATH, $SCRIPT_NAME, $SCRIPT_DIR

if [[ -z $1 && -z $2 ]] ; then
   echo "Please specify the domain name and hostname, get domain name by:"
   echo "  virsh list --all"
   echo "Usage: "
   echo "  ${BASH_SOURCE[0]} \$dom \$hostname"
   exit 1
fi

# https://stackoverflow.com/questions/4824590/propagate-all-arguments-in-a-bash-shell-script
# echo $@, $*, "$@", "$*"

set_hostname $@
