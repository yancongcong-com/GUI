#!/usr/bin/bash
#!serverA
cipan=/dev/sdb
vg_name=datavg2
pe_size=8
lv_name=lv2
lv_size=8G
file_system=ext4
pvcreate $cipan   &>/dev/unll
vgcreate $vg_name $cipan -s $pe_size   &>/dev/unll  
lvcreate -L $lv_size -n $lv_name  $vg_name   &>/dev/unll
if [ "$file_system" = "xfs" ];then
	mkfs.xfs /dev/$vg_name/$lv_name    &>/dev/unll	
fi
if [ "$file_system" = "ext4"   ];then
       mkfs.ext4 /dev/$vg_name/$lv_name  &>/dev/unll
fi
lvm_mount=/data/web_data
[ -d $lvm_mount  ] || mkdir -p /data/web_data
uuid=`blkid |grep $vg_name-$lvname |awk '{print $2}'`
echo "$uuid  $lvm_mount  $file_system   defaults    0  0 "  >> /etc/fstab
mount -a 
[ $? -eq 0 ] && echo "lvm成功" || echo "lvm失败"
serverA_name=serverA.rj.com
echo “$serverA_name” > /etc/hostname
#hostnamectl set-hostname $serverA_name
[ $? -eq 0 ] && echo "主机名修改成功" || echo "主机名修改失败"
nfs_yum=`yum -y install nfs-utils  &> /dev/null ` 
nfs_dir=/data/web-data
nfs_net=192.168.1.0/24
$nfs_yum  && echo "$nfs_dir $nfs_net(rw,sysn,no_root_squash)" > /etc/exports
systemctl restart nfs &>/dev/unll
[ $? -eq 0 ] && echo "nfs服务启动成功" || echo "nfs服务启动失败"
systemctl enable  nfs &>/dev/null
#DNS
dns_yum=`yum -y install bind bind-utils &>/dev/null `
dns_zone=rj.com
dns_www_ip=192.168.114.139
dns_dns_ip=192.168.114.135
$dns_yum &&  sed -ri 's/127.0.0.1|localhost|::1/any/' /etc/named.conf
zone="zone \"$dns_zone\" IN { type master; file \"$dns_zone.zone\"; };"
grep $dns_zone /etc/named.conf &>/dev/unll  || echo $zone >> /etc/named.conf
[ -f  $dns_zone.zone  ] && rm -rf $dns_zone.zone
cp -rf /var/named/{named.localhost,$dns_zone.zone}
sed -ri 's/@/dns/g' /var/named/$dns_zone.zone 
sed -ri 's/^dns/@/g' /var/named/$dns_zone.zone 
sed -ri "/127.0.0.1/c dns IN  A $dns_dns_ip"  /var/named/$dns_zone.zone  
sed -ri "/AAAA/c www IN  A $dns_www_ip"  /var/named/$dns_zone.zone
dns_zone=192.168.114
fan_zone=`echo $dns_zone |awk -F"." '{print $3,$2,$1} BEGIN{OFS="."}'`
zone="zone \"$fan_zone.in-addr.arpa\" IN { type master; file \"$dns_zone.zone\"; };"
grep $dns_zone /etc/named.conf &>/dev/unll  || echo $zone >> /etc/named.conf
[ -f  $dns_zone.zone  ] && rm -rf $dns_zone.zone
cp -rf /var/named/{named.loopback,$dns_zone.zone}
sed -ri 's/@/dns/g' /var/named/$dns_zone.zone
sed -ri 's/^dns/@/g' /var/named/$dns_zone.zone
sed -ri "/127.0.0.1/c dns IN  A $dns_dns_ip"  /var/named/$dns_zone.zone
sed -ri "/AAAA/d"  /var/named/$dns_zone.zone
serverA_ip=`echo $dns_www_ip |awk -F"." '{print $NF}'`
serverB_ip=`echo $dns_dns_ip |awk -F"." '{print $NF}'`
sed -ri "/PTR/c $serverA_ip IN PTR www.rj.com"  /var/named/$dns_zone.zone
echo "$serverB_ip  IN   PTR   dns.rj.com"  >>  /var/named/$dns_zone.zone
chgrp -R named /var/named/
chmod g+s /var/named/
systemctl restart named
[ $? -eq 0 ] && echo "dns服务启动成功" || echo "dns服务启动失败"
systemctl enable  named &>/dev/null
#http
yum -y install httpd mod_ssl php &>/dev/unll
[ $? -eq  0 ] || echo " http服务安装失败" 
[ -f /etc/httpd/conf.d/ssl.conf ] &&  mv /etc/httpd/conf.d/{ssl.conf,ssl.conf.bak}
http_doc=/etc/httpd/conf.d/virthost.conf
echo "<VirtualHost $dns_www_ip:80>" > $http_doc
echo "	ServerName  www.rj.com " >> $http_doc
echo "	DocumentRoot  $lvm_mount " >> $http_doc
echo "</VirtualHost>" >> $http_doc
echo "<Directory \"$lvm_mount\" > " >> $http_doc
echo "	Require  all granted" >> $http_doc
echo "</Directory>" >> $http_doc
echo Welcome to 2019 Computer Network Application contest! > /data/web_data/index.html
chown -R apache:apache $lvm_mount
systemctl restart httpd &>/dev/unll
[ $? -eq 0 ] && echo "http服务启动成功" || echo "http服务启动失败"
systemctl enable  httpd &>/dev/null
#haproxy
yum -y install haproxy  &>/dev/null

systemctl restart haproxy &>/dev/unll
[ $? -eq 0 ] && echo "http服务启动成功" || echo "http服务启动失败"
systemctl enable  haproxy &>/dev/nul

