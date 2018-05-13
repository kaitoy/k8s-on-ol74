#!/bin/sh

set -eu

mkdir -p /etc/kubernetes/pki
chown root:root /etc/kubernetes/pki
chmod 0755 /etc/kubernetes/pki

mkdir -p /var/lib/{kubelet,kube-proxy}
chown root:root /var/lib/{kubelet,kube-proxy}
chmod 0755 /var/lib/{kubelet,kube-proxy}

mkdir -p /var/lib/etcd
chown etcd:etcd /var/lib/etcd
chmod 0755 /var/lib/etcd

mkdir -p /etc/kubernetes/manifests
chown root:root /etc/kubernetes/manifests
chmod 0755 /etc/kubernetes/manifests

mkdir -p /etc/cni/net.d /opt/cni/bin/
chown root:root /etc/cni/net.d /opt/cni/bin/
chmod 0755 /etc/cni/net.d /opt/cni/bin/

mkdir -p /var/log/kubernetes
chown kubernetes:kubernetes /var/log/kubernetes
chmod 0700 /var/log/kubernetes
