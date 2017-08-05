#!/bin/bash

# disable Plesk ONLY IF PLESK ENABLED
#/etc/init.d/psa stop
#/sbin/chkconfig --del psa
  
#local gen to avoid spurious warnings
locale-gen en_US.UTF-8
  
# update package list
echo "Updating software"
apt-get update -y

#upgrade any currently installed packages
apt-get upgrade all

# get all the packages required for compiling source
echo "Installing dev tools"
apt-get install build-essential -y

# install mkpasswd
#apt-get install mkpasswd -y

#for ubuntu 12 and later, use whois to install mkpasswd.
apt-get install whois -y

# install mysql 
echo "Installing MySQL"
apt-get install mysql-server mysql-common mysql-client libmysqlclient18 -y

# install apache
echo "Installing Apache"
#yum install httpd mod_ssl -y
apt-get install apache2 -y
apt-get install openssl -y
a2enmod ssl

# install php
echo "Installing php"
#yum install php php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-mcrypt curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel -y

apt-get install php5 php5-cgi php5-common php5-cli php5-curl php5-dev php5-gd php5-imap php5-ldap php-pear php5-xmlrpc php5-mcrypt php5-mysql libapache2-mod-php5 curl libcurl3 python-pycurl libwww-perl imagemagick libxml2 libxml2-dev zlibc libfreetype6 mercurial subversion git bzr libjpeg62 libpng3 git-core -y


# install http dev tools to get apxs
echo "Installing httpd-devel"
#yum install httpd-devel -y
apt-get install apache2-dev -y

# install pcre-devel tools
echo "installing pcre-devel"
#yum install pcre-devel -y
apt-get install pcregrep libpcre3 libpcre3-dev -y

# install additional packages
echo "Installing additional packages"
#yum install wget bzip2 unzip zip openssl  -y
apt-get install wget bzip2 unzip zip -y

# install SNMP support
echo "installing snmp"
#yum install net-snmp net-snmp-devel net-snmp-libs net-snmp-perl net-snmp-utils php-snmp -y

apt-get install snmp snmpd libsnmp-base libsnmp-dev libsnmp-perl libsnmp15 php5-snmp python-pysnmp4-apps python-pysnmp4-mibs -y

# edit proftp conf and change to valid
echo "Fixing ProFTP conf"
cp /etc/proftpd/proftpd.conf /etc/proftpd/proftpd.conf.backup
sed 's/nogroup/nobody/g' /etc/proftpd/proftpd.conf.backup > /etc/proftpd/proftpd.conf

# set mysql, apache, and proftp to start on boot
echo "Setting Apache, MySQL, and ProFTP to start at boot"
#/sbin/chkconfig httpd on
#/sbin/chkconfig --add mysqld
#/sbin/chkconfig mysqld on
#/sbin/service httpd start
#/sbin/service mysqld start
#/sbin/chkconfig --levels 235 proftpd on
#/etc/init.d/proftpd start

/usr/sbin/update-rc.d apache2 defaults
/usr/sbin/update-rc.d mysql defaults
/usr/sbin/service apache2 start
/usr/sbin/service mysql start
/usr/sbin/service proftpd start

# create expressionengine db
echo "Creating databases"
MYSQL=`which mysql`
Q1="CREATE DATABASE IF NOT EXISTS expression;"
Q2="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}"
#$MYSQL -uroot -psomepassword -e "$SQL"

# create programmer group
groupadd programmers

#create admin group
groupadd admin

#UBUNTU PASSWORD CREATION IS VERY DIFFERENT

echo "Creating user user2"
USER="user2"
PASSWORD="somepassword"
Q1="GRANT ALL ON *.* TO '$USER'@'localhost' IDENTIFIED BY '$PASSWORD';"
Q2="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}"
useradd $USER -G admin -m -s /bin/bash -p `mkpasswd $PASSWORD`
mysql -uroot -psomepassword -e "$SQL"



# Add users to sudo
echo "Adding users to sudo"
if [ -f "/etc/sudoers.tmp" ]; then
    exit 1
fi
cp /etc/sudoers /tmp/sudoers.new
echo "%admin	ALL=(ALL)	ALL" >> /tmp/sudoers.new
visudo -q -c -s -f /tmp/sudoers.new
if [ "$?" -eq "0" ]; then
    cp /tmp/sudoers.new /etc/sudoers
fi
#rm /etc/sudoers.tmp



# Create default vhost dir and files
mkdir -p /var/www/vhosts
mkdir -p /var/www/vhosts/default/conf /var/www/vhosts/default/httpdocs /var/www/vhosts/default/httpdocs/media /var/www/vhosts/default/statistics/logs
HTTPD_INCLUDE="/var/www/vhosts/default/conf/httpd.include"
echo "<VirtualHost domain.com:80>" >> HTTPD_INCLUDE
echo "  ServerName   www.domain.com" >> HTTPD_INCLUDE
echo "  ServerAlias  domain.com" >> HTTPD_INCLUDE
echo "  ServerAdmin  \"jwelch@zimmerman.com\"" >> HTTPD_INCLUDE
echo "  DocumentRoot /var/www/vhosts/domain.com/httpdocs" >> HTTPD_INCLUDE
echo "  CustomLog  /var/www/vhosts/domain.com/statistics/logs/access_log common" >> HTTPD_INCLUDE
echo "  ErrorLog  /var/www/vhosts/domain.com/statistics/logs/error_log" >> HTTPD_INCLUDE
echo "  Include /var/www/vhosts/domain.com/conf/vhost.conf" >> HTTPD_INCLUDE
echo "</VirtualHost>" >> HTTPD_INCLUDE

chown -R www-data:programmers /var/www/vhosts/default

echo "Don't forget to create the SNMPv3 users and run snmpconf!"

echo "Setting up IPTables"

#iptables v4 setup

#rule that lets it accept traffic at all

iptables -A INPUT -i lo -j ACCEPT

#don't kill existing connections while you do this

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#set up to only accept ssh, http, ftp, https

iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 21 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT

#drop everything else

iptables -A INPUT -j DROP

#make sure apt-get works

iptables -A OUTPUT -p tcp --dport 21 -d security.debian.org -j ACCEPT
iptables -A OUTPUT -p tcp --dport 21 -d volatile.debian.org -j ACCEPT
iptables -A OUTPUT -p tcp --dport 21 -d ftp.br.debian.org -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80 -d ftp.br.debian.org -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80 -d security.debian.org -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80 -d volatile.debian.org -j ACCEPT

# List of ip addresses we just autoblock

iptables -A INPUT -s bad.ip.add.ress -j DROP

#save this

iptables-save

#iptables v6 setup

#rule that lets it accept traffic at all

ip6tables -A INPUT -i lo -j ACCEPT

#don't kill existing connections while you do this

ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#set up to only accept ssh, http, ftp, https

ip6tables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
ip6tables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
ip6tables -A INPUT -p tcp -m tcp --dport 21 -j ACCEPT
ip6tables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT

#drop everything else

ip6tables -A INPUT -j DROP

#make sure apt-get works

ip6tables -A OUTPUT -p tcp --dport 21 -d security.debian.org -j ACCEPT
ip6tables -A OUTPUT -p tcp --dport 21 -d volatile.debian.org -j ACCEPT
ip6tables -A OUTPUT -p tcp --dport 21 -d ftp.br.debian.org -j ACCEPT
ip6tables -A OUTPUT -p tcp --dport 80 -d ftp.br.debian.org -j ACCEPT
ip6tables -A OUTPUT -p tcp --dport 80 -d security.debian.org -j ACCEPT
ip6tables -A OUTPUT -p tcp --dport 80 -d volatile.debian.org -j ACCEPT

# List of ip addresses we just autoblock

ip6tables -A INPUT -s 0:0:0:0:0:ffff:badip:address -j DROP


ip6tables-save

#install iptables-persistent

echo "INSTALLING IPTABLES PERSISTENT. MAKE SURE YOU PAY ATTENTION TO HOW THIS INSTALLS SO YOU USE THE RIGHT RULES FILE"
apt-get install iptables-persistent -y
sed -i 's/\(modprobe -q ip6\?table_filter\)/\1 || true/g' /var/lib/dpkg/info/iptables-persistent.postinst; 
aptitude install iptables-persistent

echo "IPTABLES PERSISTENT INSTALLED. MAKE SURE TO SET UP THE RULES FILE(S) AND START THE SERVICE"