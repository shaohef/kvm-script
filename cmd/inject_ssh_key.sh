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

function inject_ssh_key(){
  # $1 domain, $2 USER $3 Key path
  USER=${2:-$USER}
  USER=${USER:-root}
  KEY=$(realpath ~/.ssh/id_rsa.pub)
  # echo $KEY
  FILENAME=${3:-$KEY}
  [[ "$USER" == "root" ]] && KEYPATH="/root/.ssh/" || KEYPATH="/home/$USER/.ssh/"
  # These 2 commands does not works
  # https://bugzilla.redhat.com/show_bug.cgi?id=1378311
  virt-customize -d $1 --ssh-inject $USER:file:$FILENAME --selinux-relabel
  # virt-sysprep -d $1 --ssh-inject $USER:file:$FILENAME
  # virt-copy-in -d $1 $KEY $KEYPATH
}


# echo $ABSOLUTE_PATH, $SCRIPT_NAME, $SCRIPT_DIR

if [[ -z $1 ]] ; then
   echo "Please specify the domain name, get domain name by:"
   echo "  virsh list --all"
   echo "Usage: "
   echo "  ${BASH_SOURCE[0]} \$dom \$user \$key_file"
   echo "user: default as the current user run this script"
   echo " key_file: default '~/.ssh/id_rsa.pub'"
   exit 1
fi

# https://stackoverflow.com/questions/4824590/propagate-all-arguments-in-a-bash-shell-script
# echo $@, $*, "$@", "$*"

inject_ssh_key $@
