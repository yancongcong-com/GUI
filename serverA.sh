#!/usr/bin/bash
#serverA
systemctl stop firewalld.service  >/dev/null
systemctl disable firewalld.service &>/dev/null
sed -ri '/^SELINUX=/cSELINUX=disabled' /etc/selinux/config >/dev/null
setenforce 0 
x=1
A=22
network=33
cat > /etc/sysconfig/network-scripts/ifcfg-ens$network <<-EOF 
TYPE=Ethernet
BOOTPROTO=none
NAME=ens$network
DEVICE=ens$network
IPADDR=172.16.$x.$A
PREFIX=24 
GATEWAY=172.16.$x.2 
DNS1=114.114.114.114
ONBOOT=yes
EOF
#    
network=37
cat > /etc/sysconfig/network-scripts/ifcfg-ens$network <<-EOF
TYPE=Ethernet
BOOTPROTO=none
NAME=ens$network
DEVICE=ens$network
IPADDR=192.168.$x.$A
PREFIX=24
GATEWAY=192.168.$x.2
DNS1=114.114.114.114
ONBOOT=yes
EOF
##disk
disk=/dev/sdc
vg_name=datasotre
pe_size=8
lv_name=database
lv_size=8G
file_system=ext4
pvcreate $disk   &>/dev/unll
vgcreate $vg_name $disk -s $pe_size   &>/dev/unll  
lvcreate -L $lv_size -n $lv_name  $vg_name   &>/dev/unll
if [ "$file_system" = "xfs" ];then
	mkfs.xfs /dev/$vg_name/$lv_name    &>/dev/unll	
fi
if [ "$file_system" = "ext4"   ];then
       mkfs.ext4 /dev/$vg_name/$lv_name  &>/dev/unll
fi
lvm_mount=/data/web_data
[ -d $lvm_mount  ] || mkdir -p $lvm_mount
uuid=`blkid |grep $vg_name-$lv_name |awk '{print $2}'`
grep $uuid /etc/fstab >/dev/null  || echo "$uuid  $lvm_mount  $file_system   defaults    0  0 "  >> /etc/fstab
mount -a 
[ $? -eq 0 ] && echo "lvm成功" || echo "lvm失败"
serverA_name=serverA.rj.com
echo "$serverA_name" > /etc/hostname
#hostnamectl set-hostname $serverA_name
[ $? -eq 0 ] && echo "主机名修改成功" || echo "主机名修改失败"
nfs_yum=`yum -y install nfs-utils  &> /dev/null ` 
nfs_dir=/data/web_data
nfs_net=192.168.1.0/24
$nfs_yum  && echo "$nfs_dir $nfs_net(rw,no_root_squash)" > /etc/exports
systemctl restart nfs &>/dev/unll
[ $? -eq 0 ] && echo "nfs服务启动成功" || echo "nfs服务启动失败"
systemctl enable  nfs &>/dev/null
#DNS
dns_yum=`yum -y install bind bind-utils &>/dev/null `
dns_zone=rj.com
dns_www_ip=172.16.1.22
dns_dns_ip=172.16.1.33
#正向解析
$dns_yum &&  sed -ri 's/127.0.0.1|localhost|::1/any/' /etc/named.conf
zone="zone \"$dns_zone\" IN { type master; file \"$dns_zone.zone\"; };"
grep $dns_zone /etc/named.conf &>/dev/unll  || echo $zone >> /etc/named.conf
[ -f  $dns_zone.zone  ] && rm -rf $dns_zone.zone
cp -rf /var/named/{named.localhost,$dns_zone.zone}
sed -ri 's/@/dns/g' /var/named/$dns_zone.zone 
sed -ri 's/^dns/@/g' /var/named/$dns_zone.zone
sed -ri 's/dns$/ftp/g' /var/named/$dns_zone.zone
sed -ri "/127.0.0.1/c ftp IN  A $dns_dns_ip"  /var/named/$dns_zone.zone  
sed -ri "/AAAA/c www IN  A $dns_www_ip"  /var/named/$dns_zone.zone
#反向解析
dns_zone=172.16.1
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
echo "$serverB_ip  IN   PTR   ftp.rj.com"  >>  /var/named/$dns_zone.zone
chgrp -R named /var/named/
chmod g+s /var/named/
systemctl restart named
[ $? -eq 0 ] && echo "dns服务启动成功" || echo "dns服务启动失败"
systemctl enable  named &>/dev/null
#http
#yum -y install httpd mod_ssl php &>/dev/unll
#[ $? -eq  0 ] || echo " http服务安装失败" 
#[ -f /etc/httpd/conf.d/ssl.conf ] &&  mv /etc/httpd/conf.d/{ssl.conf,ssl.conf.bak}
#http_doc=/etc/httpd/conf.d/virthost.conf
#echo "<VirtualHost $dns_www_ip:80>" > $http_doc
#echo "	ServerName  www.rj.com " >> $http_doc
#echo "	DocumentRoot  $lvm_mount " >> $http_doc
#echo "</VirtualHost>" >> $http_doc
#echo "<Directory \"$lvm_mount\" > " >> $http_doc
#echo "	Require  all granted" >> $http_doc
#echo "</Directory>" >> $http_doc
#echo Welcome to 2019 Computer Network Application contest! > /data/web_data/index.html
#chown -R apache:apache $lvm_mount
#systemctl restart httpd &>/dev/unll
#[ $? -eq 0 ] && echo "http服务启动成功" || echo "http服务启动失败"
#systemctl enable  httpd &>/dev/null
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
    listen       192.168.1.22:80;
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
echo Welcome to 2019 Computer Network Application contest! > /data/web_data/index.html

#haproxy
#yum -y install haproxy  &>/dev/null
#
#systemctl restart haproxy &>/dev/unll
#[ $? -eq 0 ] && echo "http服务启动成功" || echo "http服务启动失败"
#systemctl enable  haproxy &>/dev/nul
#ssl+httpi
systemctl restart nginx  &>/dev/null
[ $? -eq 0 ] && echo "https服务启动成功" || echo "https服务启动失败"
systemctl enable  nginx  &>/dev/null
cd /data/web_data
yum -y install wget &>/dev/null
wget https://wordpress.org/wordpress-4.3.20.tar.gz &>/dev/null
tar -xf wordpress-4.3.20.tar.gz -C /data/web_data
chown -R nginx:nginx /data/web_data/
ystemctl restart nginx  &>/dev/null
#[ $? -eq 0 ] && echo "wordpress服务启动成功" || echo "wordpress服务启动失败"
#ffff
cat > /etc/nginx/conf.d/proxy.conf <<-EOF
upstream web{
        server 192.168.1.22:80;
        server 192.168.1.33:80;
}
server {
        listen      172.16.1.22:80;
        server_name  www.rj.com;
        location / {
                proxy_pass http://web;
                proxy_set_header Host $host;
                proxy_set_header   X-Real-IP        $remote_addr;
                proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
                 root   /data/web_data;
                index  index.php index.html index.htm;
        }
}
server {
        listen       172.16.1.22:443;
        server_name  www.rj.com;
        location / {
                proxy_pass http://web;
                proxy_set_header Host $host;
                proxy_set_header   X-Real-IP        $remote_addr;
                proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
                 root   /data/web_data;
                index  index.php index.html index.htm;

       }
}
EOF
#
systemctl restart nginx php-fpm &>/dev/null
[ $? -eq 0 ] && echo "负载均衡服务启动成功" || echo "负载均衡服务启动失败"
systemctl enable  nginx php-fpm &>/dev/null


