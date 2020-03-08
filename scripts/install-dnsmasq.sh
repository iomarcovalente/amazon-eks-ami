#!/bin/bash

# install dns caching
yum install -y bind-utils
yum install -y dnsmasq
groupadd -r dnsmasq
useradd -r -g dnsmasq dnsmasq
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
cat <<EOF > /etc/dnsmasq.conf
# Server Configuration
listen-address=127.0.0.1
port=53
bind-interfaces
user=dnsmasq
group=dnsmasq
pid-file=/var/run/dnsmasq.pid

# Name resolution options
resolv-file=/etc/resolv.dnsmasq
cache-size=500
neg-ttl=60
min-cache-ttl=${DNSMASQ_CACHE_TTL}
domain-needed
bogus-priv
EOF
echo "nameserver 169.254.169.253" > /etc/resolv.dnsmasq
systemctl restart dnsmasq.service
systemctl enable dnsmasq.service
echo "supersede domain-name-servers 127.0.0.1, 169.254.169.253;" >> /etc/dhcp/dhclient.conf && dhclient
# testing dnsmasq
dig aws.amazon.com
