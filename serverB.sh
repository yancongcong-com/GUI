#!/bin/bash
#serverB
##network
systemctl stop firewalld.service  >/dev/null
systemctl disable firewalld.service &>/dev/null
sed -ri '/^SELINUX=/cSELINUX=disabled' /etc/selinux/config >/dev/null
setenforce 0 
x=1
B=33
network=33
cat > /etc/sysconfig/network-scripts/ifcfg-ens$network <<-EOF 
TYPE=Ethernet
BOOTPROTO=none
NAME=ens$network
DEVICE=ens$network
IPADDR=172.16.$x.$B
PREFIX=24 
GATEWAY=172.16.$x.2 
DNS1=114.114.114.114
ONBOOT=yes
EOF
#
[ $? -eq 0 ] && echo "网卡1成功" || echo "网卡1失败"     
network=37
cat > /etc/sysconfig/network-scripts/ifcfg-ens$network <<-EOF
TYPE=Ethernet
BOOTPROTO=none
NAME=ens$network
DEVICE=ens$network
IPADDR=192.168.$x.$B
PREFIX=24
GATEWAY=192.168.$x.2
DNS1=114.114.114.114
ONBOOT=yes
EOF
[ $? -eq 0 ] && echo "网卡2成功" || echo "网卡2失败"    
##disk
disk=/dev/sdb
file_system=xfs
if [ "$file_system" = "xfs" ];then
        mkfs.xfs /dev/$disk    &>/dev/unll
fi
if [ "$file_system" = "ext4"   ];then
       mkfs.ext4 /dev/$disk  &>/dev/unll
fi
echo "挂载"
mount=/data/database
[ -d $mount  ] || mkdir -p $mount
uuid=`blkid |grep $disk |awk '{print $2}'`
grep $uuid /etc/fstab >/dev/null || echo "$uuid  $mount  $file_system   defaults    0  0 "  >> /etc/fstab
echo "挂载中"
mount -a  &>/dev/null
[ $? -eq 0 ] && echo "mount成功" || echo "mount失败"
serverB_name=serverB.rj.com
echo "$serverB_name" > /etc/hostname
#hostnamectl set-hostname $serverB_name
[ $? -eq 0 ] && echo "主机名修改成功" || echo "主机名修改失败"
#nfs
nfs_mount=/data/web_data
[ -d $nfs_mount  ] || mkdir -p $nfs_mount
yum -y install nfs-utils &> /dev/null
serverA=192.168.1.22
grep $serverA  /etc/fstab  >/dev/null   || echo "$serverA:$nfs_mount  $nfs_mount  nfs  defaults,_netdev  0 0  " >> /etc/fstab
mount -a &>/dev/null
[ $? -eq 0 ] && echo "nfs挂载成功" || echo "nfs挂载失败"
#DNS
DNS_Server=172.16.1.22
www=172.16.1.22
dns=172.16.1.33
#grep "$DNS_Server"  /etc/resolv.conf  >/dev/null || sed -ri "/nameserver/cnameserver  $DNS_Server"  /etc/resolv.conf
#serverA=`ping $www -c 1 |grep PING |awk '{print$3}'|awk -F"(" '{print$2}'|awk -F")" '{print$1}'`
#[ $serverA == $www ] && echo "www解析成功" || echo "www解析失败"
#serverB=`ping $dns -c 1 |grep PING |awk '{print$3}'|awk -F"(" '{print$2}'|awk -F")" '{print$1}'`
#[ $serverB == $dns ] && echo "ftp解析成功" || echo "ftp解析失败"
#[ $? -eq 0 ] && echo "DNS解析成功" || echo "DNS解析失败"
#http
#mariadb
yum -y install mariadb mariadb-server &> /dev/null
datadir=/data/database
chown mysql:mysql $datadir -R
grep 'datadir=/data/database' /etc/my.cnf >/dev/null || sed -ri '/datadir=/cdatadir=/data/database' /etc/my.cnf
grep 'innodb_file_per_table = 1' /etc/my.cnf >/dev/null || sed -ri '/datadir=/ainnodb_file_per_table = 1' /etc/my.cnf
grep "bind-address=192.168.$x.33" /etc/my.cnf >/dev/null || sed -ri "/datadir=/abind-address=192.168.$x.33" /etc/my.cnf
grep 'skip-name-resolve' /etc/my.cnf >/dev/null || sed -ri '/datadir=/askip-name-resolve' /etc/my.cnf
systemctl restart mariadb &>/dev/unll
[ $? -eq 0 ] && echo "mariadb服务启动成功" || echo "mariadb服务启动失败"
systemctl enable  mariadb &>/dev/null
echo "create database wordpress character set utf8 collate utf8_bin;" |mysql &>/dev/null
echo "grant all privileges on wordpress.* to 'wordpress'@'192.168.1.%' identified by '';" |mysql 
echo " flush privileges;" |mysql
systemctl restart mariadb &>/dev/unll
[ $? -eq 0 ] && echo "mariadb用户授权成功" || echo "mariadb用户授权失败"
systemctl enable  mariadb &>/dev/null
#nginx
yum -y install nginx php php-fpm php-mysql php-gd gd &>/dev/null
chown -R nginx:nginx /data/web_data
sed -ri '/^user/cuser = nginx' /etc/php-fpm.d/www.conf
sed -ri '/^group/cgroup = nginx' /etc/php-fpm.d/www.conf
ssl_dir=/etc/nginx/ssl
[ -d $ssl_dir  ] || mkdir -p $ssl_dir
cd $ssl_dir
openssl genrsa  -out nginx.key 1024 &>/dev/null
openssl req -new -key nginx.key -out nginx.csr -days 365 -subj /C=CN/ST=Shanxi/L=Shanxi/O=ca/OU=ca/CN=www.rj.com/emaliAddress=ca@rj.com &>/dev/null
openssl x509 -req -days 365 -in nginx.csr -signkey nginx.key -out nginx.crt &>/dev/null
###
cat  > /etc/nginx/conf.d/wordpress.conf <<-EOF
server {
    listen              443 ssl;
    server_name         www.rj.com;
    ssl_certificate     /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    location / {
        root   /data/web_data;
        index  index.php index.html index.htm;
    }
       location ~ \.php$ {
        root           /data/web_data;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        include        fastcgi_params;
    }
}
server {
    listen       192.168.1.33:80;
    server_name  www.rj.com;

    #charset koi8-r;
    #access_log  /var/log/nginx/host.access.log  main;
    location / {
        root   /data/web_data;
        index  index.php index.html index.htm;
    }
    location ~ \.php$ {
        root           /data/web_data;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        include        fastcgi_params;
    }
}
EOF
sed -ri '/fastcgi_index  index.php;/afastcgi_param  SCRIPT_FILENAME   $document_root$fastcgi_script_name;' /etc/nginx/conf.d/wordpress.conf
sed -ri '/#access_log  \/var\/log\/nginx\/host.access.log  main;/arewrite ^(.*)$  https:\/\/$server_name$1 permanent;' /etc/nginx/conf.d/wordpress.conf
systemctl restart nginx php-fpm &>/dev/null
[ $? -eq 0 ] && echo "nginx服务启动成功" || echo "nginx服务启动失败"
systemctl enable  nginx php-fpm &>/dev/null
 

