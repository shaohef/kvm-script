#!/bin/bash 

# declare -A EDGE1_MACS EDGE2_MACS EDGE3_MACS HUB_MACS CLOUD_MACS

# MACS=(EDGE1_MACS EDGE2_MACS EDGE3_MACS HUB_MACS CLOUD_MACS)
# above 4.3 alpha version support nameref
# declare -A MACS=([EDGE1]="" [EDGE2]="" [EDGE3]="" [HUB]="" [CLOUD]="")

# SCRIPT="$(readlink --canonicalize-existing "$0")"
ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# echo $ABSOLUTE_PATH, $SCRIPT_NAME, $SCRIPT_DIR

source ${SCRIPT_DIR}/../src/global.vars
for i in `ls ${SCRIPT_DIR}/../src/utils/*`; do
  echo "source $i"
  source $i
done

END=${1:-5}
declare -p MACS
len=${#MACS[@]}
if [ $len -eq 0 ] ; then
   echo "Please define MACS as follow exampel:"
   echo '  declare -A MACS=([EDGE1]="" [EDGE2]="" [EDGE3]="" [HUB]="" [CLOUD]="")'
   echo 'EDGE1, EDGE2, EDGE3, HUB, CLOUD are hostname.'
   echo "${BASH_SOURCE[0]} \${pool_lenth:-5}"
fi

for i in "${!MACS[@]}"; do
  for j in $(seq 1 $END); do MACS[$i]=$(genmac)" "${MACS[$i]}; done 
  echo "export ${i}_MACS=\"${MACS[$i]}\"" >> ~/.bashrc
done
