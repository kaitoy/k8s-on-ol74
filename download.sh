#!/bin/sh

set -ue

curl -OL https://storage.googleapis.com/kubernetes-release/release/v1.10.0/bin/linux/amd64/hyperkube
curl -OL https://storage.googleapis.com/kubernetes-release/release/v1.10.0/bin/linux/amd64/kubeadm
mv hyperkube /usr/bin/
mv kubeadm /usr/bin/
ln -s /usr/bin/hyperkube /usr/bin/kube-apiserver
ln -s /usr/bin/hyperkube /usr/bin/kube-controller-manager
ln -s /usr/bin/hyperkube /usr/bin/kube-scheduler
ln -s /usr/bin/hyperkube /usr/bin/kube-proxy
ln -s /usr/bin/hyperkube /usr/bin/kubelet
ln -s /usr/bin/hyperkube /usr/bin/kubectl
chown root:root /usr/bin/kube*
chmod 0755 /usr/bin/kube*

curl -OL https://github.com/coreos/etcd/releases/download/v3.1.12/etcd-v3.1.12-linux-amd64.tar.gz
tar zxf etcd-v3.1.12-linux-amd64.tar.gz
mv etcd-v3.1.12-linux-amd64/etcd* /usr/bin/
chown root:root /usr/bin/etcd*
chmod 0755 /usr/bin/etcd*

pushd /opt/cni/bin
curl -OL https://github.com/containernetworking/cni/releases/download/v0.6.0/cni-amd64-v0.6.0.tgz
curl -OL https://github.com/containernetworking/plugins/releases/download/v0.7.1/cni-plugins-amd64-v0.7.1.tgz
tar zxf cni-amd64-v0.6.0.tgz
tar zxf cni-plugins-amd64-v0.7.1.tgz
rm -f cni-amd64-v0.6.0.tgz cni-plugins-amd64-v0.7.1.tgz
chown root:root *
chmod 0755 *
popd
cat >/etc/cni/net.d/99-loopback.conf <<EOF
{
  "type": "loopback"
}
EOF
