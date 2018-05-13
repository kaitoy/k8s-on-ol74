#!/bin/sh

K8S_SERVICE_IP=10.0.0.1
MASTER_IP=192.168.171.200
KUBERNETES_PUBLIC_ADDRESS=$MASTER_IP
CLUSTER_NAME="k8s"
SERVICE_CLUSTER_IP_RANGE="10.0.0.0/16"
CLUSTER_CIDR="10.32.0.0/16"

ETCD_MEMBER_NAME=etcd1
ETCD_TOKEN=$(openssl rand -hex 5)
ETCD_CLUSTER_TOKEN=$CLUSTER_NAME-$ETCD_TOKEN

DNS_SERVER_IP=10.0.0.10
DNS_DOMAIN="cluster.local"

CA_DAYS=5475
APISERVER_DAYS=5475
APISERVER_KUBELET_CLIENT_DAYS=5475
ADMIN_DAYS=5475
CONTROLLER_MANAGER_DAYS=5475
SCHEDULER_DAYS=5475
PROXY_DAYS=5475
FRONT_PROXY_CA_DAYS=5475
FRONT_PROXY_CLIENT_DAYS=5475
ETCD_CA_DAYS=5475
ETCD_DAYS=5475
ETCD_CLIENT_DAYS=5475
ETCD_PEER_DAYS=5475

SECRET_ENC_KEY=$(echo -n 'your_32_bytes_secure_private_key' | base64)
PAUSE_IMAGE=k8s.gcr.io/pause-amd64:3.1
NODE_USER_NAME=k8s-master

