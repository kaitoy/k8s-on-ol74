#!/bin/sh

set -ue

source ./env.sh

curl -LO https://raw.githubusercontent.com/coredns/deployment/master/kubernetes/coredns.yaml.sed
curl -LO https://raw.githubusercontent.com/coredns/deployment/master/kubernetes/deploy.sh
chmod +x deploy.sh
./deploy.sh -r $SERVICE_CLUSTER_IP_RANGE -i $DNS_SERVER_IP -d $DNS_DOMAIN > coredns.yaml

kubectl apply -f coredns.yaml
sleep 20
