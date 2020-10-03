#!/usr/bin/bash
#serverB
cipan=/dev/sdd
file_system=xfs
if [ "$file_system" = "xfs" ];then
        mkfs.xfs /dev/$cipan    &>/dev/unll
fi
if [ "$file_system" = "ext4"   ];then
       mkfs.ext4 /dev/$cipan  &>/dev/unll
fi
mount=/data/database
[ -d $mount  ] || mkdir -p $mount
uuid=`blkid |grep $cipan |awk '{print $2}'`
grep $uuid /etc/fstab >/dev/null || echo "$uuid  $mount  $file_system   defaults    0  0 "  >> /etc/fstab
mount -a
[ $? -eq 0 ] && echo "mount成功" || echo "mount失败"
serverB_name=serverB.rj.com
echo “$serverB_name” > /etc/hostname
#hostnamectl set-hostname $serverB_name
[ $? -eq 0 ] && echo "主机名修改成功" || echo "主机名修改失败"
#nfs
nfs_mount=/data/web_data
[ -d $nfs_mount  ] || mkdir -p $nfs_mount
yum -y install nfs-utils &> /dev/null
serverA=192.168.114.139
serverB=192.168.114.135
grep $serverA  /etc/fstab  >/dev/null   || echo "$serverA:$nfs_mount  $nfs_mount  nfs  defaults,_netdev  0 0  " >> /etc/fstab
mount -a 
[ $? -eq 0 ] && echo "nfs挂载成功" || echo "nfs挂载失败"

