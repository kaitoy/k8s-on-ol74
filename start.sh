#!/bin/sh

set -ue

systemctl start etcd
sleep 5s

systemctl start kube-apiserver
sleep 10s

systemctl start kube-controller-manager
sleep 10s

systemctl start kube-scheduler
sleep 5s
