function gen_resize_lvm_script(){
FILE=/tmp/vir_domain/resize_lvm.sh
cat > $FILE << EOF
# vgdisplay
lvextend -l +100%FREE ${2:-/dev/mapper/centos-root} >> /root/boot1.log
${1:-xfs_growfs} ${2:-/dev/mapper/centos-root} >> /root/boot1.log
# df -h
EOF
echo "$FILE"
}

# get_dom_1st_disk domain_name
function get_dom_1st_disk(){
    # $1 domain name
    FIRST_DISK_EXP='//disk[1][@device="disk"]/source/@file'
    tmpxml=/tmp/vir_domain/tmp.xml
    mkdir -p /tmp/vir_domain
    virsh dumpxml $1 > $tmpxml
    img=$(xmllint --xpath $FIRST_DISK_EXP $tmpxml | awk -F'[="]' '!/>/{print $(NF-1)}')
    echo "$img"
}


function check_resize_dom_lvm_1st_arg(){
  if [ -z "$1" ]; then
    virsh list --all
    echo "usage:"
    echo "  resize_dom_lvm domain|file size_G disk volume script_file "
    return 1
  fi

  if [[ ! -f "$1" ]] ; then
     virsh dominfo $1
     ret=$?
     [[ $ret -ne 0 ]] && return $ret
  fi
}


function check_resize_dom_lvm_2st_arg(){
  if [ -z "$2" ]; then
    echo "Error: missing the size parameters(\$2): "
    virt-filesystems --long -h --all -a $1
    echo "Get the resize disk(\$3) and lvm(\$4) from above information"
    echo "And generate resize script by this command:"
    echo "  gen_resize_lvm_script"
    echo "Check the script is right"
    return 1
  fi
}

function parser_disk_info(){
  # $1 image
  img=$1
  # 0 last partition, 1 last pv 2. last vg 3. last vg parent 4. root lv, 5. file type 6. is lvm (check pv)
  ret=()
  fsys=$(virt-filesystems --long -h --all -a $img)

  # ---------------------- 0 last partition -----------------------
  partn=$(echo "$fsys" |grep -o "/dev/[A-Za-z1-9 ]*partition"|sort|tail -n 1)
  # partndev=$(echo "$partn" | awk '{print $1}')
  partndev=${partn%% *}
  ret+=("$partndev")
  # ---------------------- 1 last pv        -----------------------
  pvn=$(echo "$fsys" |grep -o "/dev/[A-Za-z1-9 ]*pv"|sort|tail -n 1)
  pvndev=$(echo "$pvn" | awk '{print $1}')
  # disk=${3:-/dev/sda2}
  ret+=("$pvndev")
  # pvndev=${3:-$pvndev}

  # ---------------------- 2 last vg        -----------------------
  vgn=$(echo "$fsys" |grep -o "/dev/[A-Za-z1-9]*[[:space:]]*vg.*"|sort|tail -n 1)
  vgdev=$(echo "$vgn" | awk '{print $1}')
  ret+=("$vgdev")

  # ---------------------- 3 last vg parent -----------------------
  vgnp=${vgn##* }
  ret+=("$vgnp")

  # ---------------------- 4 root lv    -----------------------
  lv=$(echo "$fsys" |grep "${vgdev}/root[[:space:]]*.*${vgdev}"|sort|tail -n 1)
  lvroot=$(echo "$lv" | awk '{print $1}')
  # lvroot=${4:-$lvroot}
  ret+=("$lvroot")

  # ---------------------- 5 file type -----------------------
  fs=$(echo "$fsys" |grep "${lvroot}[[:space:]]*filesystem")
  fstype=$(echo "$fs" | awk '{print $3}')
  ret+=("$fstype")

  # ---------------------- 6 is lvm   -----------------------
  declare -p ret
  # echo $pvn, $vgn, $fs, $vgdev
  echo $pvndev, $lvroot, $fstype
}



function parser_disk_lv_info(){
  # $1 image
  img=$1
  # 0 last partition, 1 last pv 2. last vg 3. last vg parent 4. root vg, 5. file type 6. is lvm (check pv)
  ret=()
  fsys=$(virt-filesystems --long -h --all -a $img)
  vgn=$(echo "$fsys" |grep -o "/dev/[A-Za-z1-9]*[[:space:]]*vg[[:space:]]*.*/dev/[A-Za-z1-9]*"|sort|tail -n 1)
  vgdev=${vgn%% *}
  vgnp=${vgn##* }
  lv=$(echo "$fsys" |grep -v "swap" |grep "${vgdev}/.*[[:space:]]*.*${vgdev}"|sort|tail -n 1)
  fs=$(echo "$fsys" |grep -v "swap" |grep "${vgdev}/.*[[:space:]]*filesystem"|sort|tail -n 1)
  fstype=$(echo "$fs" | awk '{print $3}')

  IFS=',' array=($vgnp) ; unset IFS
  len=${#array[@]}
  pdevlast=${array[@]: -1}
  pdev1st=${array[0]}
  # a bug for virt-filesystems
  if [[ "$pdevlast" == "$pdev1st" && $len -gt 0 ]] ; then
    base=${pdev1st%%[[:digit:]]*}
    idx=${pdev1st##${base}}
    idx=$(($len -1 + $idx))
    # echo $pdev1st $base $idx
    pdevlast=${base}${idx}
  fi
  # echo $vgdev: $vgnp: $lv: $fs: $fstype, $len, $pdevlast $pdev1st
  echo "${lv%% *}, $fstype, $pdev1st, $pdevlast"
}


# resize_dom_lvm domain script_file size_G  # only test on centos7.9
function resize_dom_lvm(){
  # $1 domain name $2 size $3 disk $4 volume  # $5 resize script
  check_resize_dom_lvm_1st_arg $1
  ret=$?
  [[ $ret -ne 0 ]] && return $ret

  [[ ! -f "$1" && "running" == "$(virsh domstate $1)" ]] && echo "The vm in running, exit" && ret=1
  [[ $ret -ne 0 ]] && return $ret

  [[ -f "$1" ]] && img=$1 || img=$(get_dom_1st_disk $1)

  check_resize_dom_lvm_2st_arg $img $2
  ret=$?
  [[ $ret -ne 0 ]] && return $ret
  size=${2:-20G}
  img_size=$(qemu-img info --output json $img | grep "virtual-size" | awk -F"[,:]" '{print $2}')
  osize=$(($img_size/1024/1024/1024))
  nsize=${size%%[^0-9]*}
  [[ "$(($osize + 1))" -gt "$nsize"  ]] && echo "The original image size is ${osize}G. Please imput a bigger size." && return 1

  lvinfo=$(parser_disk_lv_info $1)
  IFS=', ' array=($lvinfo); unset IFS
  lvroot=${4:-${array[0]}}
  fstype=${array[1]}
  pv_disk=${3:-${array[2]}}
  [[ "xfs" == "$fstype" ]] && fs_cmd=xfs_growfs || fs_cmd=resize2fs
  script=$(gen_resize_lvm_script $fs_cmd $lvroot)
  # virt-sysprep can also works
  # [[ -f "$1" ]] && virt-customize -a $1 --firstboot $script || virt-customize -d $1 --firstboot $script

  tmp_img=${img%/*}/temporary.${img#*.}
  echo "qemu-img create -f qcow2 -o preallocation=metadata $tmp_img $size"
  echo "Generate a intermediate images: $tmp_img"
  qemu-img create -f qcow2 -o preallocation=metadata $tmp_img $size

  virt-filesystems --long -h --all -a $img
  # https://blog.csdn.net/tutucute0000/article/details/38414449
  echo "virt-resize --expand $pv_disk --LV-expand $lvroot $img $tmp_img"
  virt-resize --expand $pv_disk --LV-expand $lvroot "$img" "$tmp_img"
  echo "virt-customize -a $tmp_img --run $script"
  virt-customize -a $tmp_img --run $script
  virt-filesystems --long -h --all -a $tmp_img
  if [[ $ret -eq 0 ]] ; then
    echo "mv $tmp_img $img -f"
    mv $tmp_img $img -f
  else
    echo "NOTE: Please double chech and run the follow command manually\!"
    echo "  mv $tmp_img $img -f"
  fi
}
