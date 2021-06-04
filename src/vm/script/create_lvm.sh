if [[ -z $1 && -z $2 ]] ; then
   echo "Please specify the partition for pv, and lvm name."
   echo "Get block information by:"
   echo "  lsblk"
   echo "  blkid"
   echo "Get lvm informaiton by:"
   echo "  lvdisplay"
   echo "Usage: "
   echo "  ${BASH_SOURCE[0]} \$dev \$lv_path"
   echo "Example: "
   echo "  ${BASH_SOURCE[0]} sdc /dev/centos/root"
   exit 1
fi

# https://superuser.com/questions/332252/how-to-create-and-format-a-partition-using-a-bash-script
echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/$1

# https://cloud.tencent.com/developer/article/1671893
pvcreate /dev/${1}1
pvdisplay
vgextend centos /dev/${1}1
vgdisplay
lvextend -l +100%FREE $2
lvdisplay $2
xfs_growfs $2
df -h
