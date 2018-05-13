#!/bin/sh

set -ue

cat /etc/fstab |grep -v swap > /tmp/fstab
mv -f /tmp/fstab /etc/fstab
swapoff -a

SELINUX=permissive
sed -E 's/SELINUX=((enforcing)|(disabled))/SELINUX=permissive/' /etc/selinux/config > /tmp/config
mv -f /tmp/config /etc/selinux/config
setenforce 0

systemctl stop firewalld
systemctl disable firewalld

modprobe br_netfilter
echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf

cat > /etc/sysctl.d/kubernetes.conf << EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl -p /etc/sysctl.d/kubernetes.conf

yum install -y yum-utils
yum-config-manager --enable ol7_addons
yum install -y docker-engine conntrack-tools

echo DOCKER_NOFILE=1000000 >> /etc/sysconfig/docker
sed -E "s/OPTIONS='[^']+'/OPTIONS='--selinux-enabled --iptables=false'/" /etc/sysconfig/docker > /tmp/docker
mv -f /tmp/docker /etc/sysconfig/docker

systemctl daemon-reload
systemctl enable docker
systemctl start docker
