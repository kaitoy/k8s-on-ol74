#!/bin/sh

set -ue

curl -fsSLo weave-daemonset.yaml "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.CHECKPOINT_DISABLE=1&password-secret=weave-passwd"

WEAVE_PASSWORD=$(echo -n 'your_secure_password' | base64)
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Secret
metadata:
  namespace: kube-system
  name: weave-passwd
type: Opaque
data:
  weave-passwd: ${WEAVE_PASSWORD}
EOF

kubectl apply -f weave-daemonset.yaml
sleep 20
