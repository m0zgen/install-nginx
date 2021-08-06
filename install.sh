#!/bin/bash
# Install NGINX Web Server to CentOS
# Created by Y.G., https://sys-adm.in

# Envs
# ---------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
cd $SCRIPT_PATH

# Helper folder
DEST=${SCRIPT_PATH}/helpers

if [[ ! -d '$DEST' ]]; then
	mkdir -p $DEST
fi

# Install some require software
# ---------------------------------------------------\
yum install epel-release yum-utils -y

# Add NGINX official repo and install him
# ---------------------------------------------------\
# http://nginx.org/en/linux_packages.html
cat > /etc/yum.repos.d/nginx.repo <<_EOF_
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
_EOF_

yum-config-manager --enable nginx-mainline
yum install nginx -y

# SELinux module
# ---------------------------------------------------\
cat > $DEST/nginx.te <<_EOF_
module nginx 1.0;
require {
	type httpd_t;
	type user_home_t;
	type init_t;
	class sock_file write;
	class unix_stream_socket connectto;
	class file read;
}
#============= httpd_t ==============
#!!!! This avc is allowed in the current policy
allow httpd_t init_t:unix_stream_socket connectto;
#!!!! This avc can be allowed using the boolean 'httpd_read_user_content'
allow httpd_t user_home_t:file read;
#!!!! This avc is allowed in the current policy
allow httpd_t user_home_t:sock_file write;
_EOF_

checkmodule -M -m -o $DEST/nginx.mod $DEST/nginx.te
semodule_package  -m $DEST/nginx.mod -o $DEST/nginx.pp
semodule -i $DEST/nginx.pp

# Enable and run NGINX
# ---------------------------------------------------\
systemctl enable --now nginx

# Checking service
# ---------------------------------------------------\
if (systemctl is-active --quiet nginx); then
        echo -e "NGINX is Running\nDone!"
else
    	echo -e "NGINX has Stopped status!"
        nginx -t
        echo -e "Please follow NGINX status bellow. Bye."
fi



