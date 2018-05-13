#!/bin/sh

set -ue

source ./env.sh

cat <<EOF | kubectl create -f -
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: auto-approve-csrs-for-group
subjects:
- kind: Group
  name: system:bootstrappers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:nodeclient
  apiGroup: rbac.authorization.k8s.io
EOF
cat <<EOF | kubectl create -f -
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${NODE_USER_NAME}-node-client-cert-renewal
subjects:
- kind: User
  name: system:node:${NODE_USER_NAME}
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:selfnodeclient
  apiGroup: rbac.authorization.k8s.io
EOF
cat <<EOF | kubectl create -f -
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: approve-node-server-renewal-csr
rules:
- apiGroups: ["certificates.k8s.io"]
  resources: ["certificatesigningrequests/selfnodeserver"]
  verbs: ["create"]
EOF
cat <<EOF | kubectl create -f -
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${NODE_USER_NAME}-server-client-cert-renewal
subjects:
- kind: User
  name: system:node:${NODE_USER_NAME}
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: approve-node-server-renewal-csr
  apiGroup: rbac.authorization.k8s.io
EOF

BOOTSTRAP_TOKEN=$(kubeadm token create --kubeconfig /etc/kubernetes/admin.kubeconfig)
kubectl -n kube-public create configmap cluster-info --from-file /etc/kubernetes/pki/ca.crt --from-file /etc/kubernetes/bootstrap.kubeconfig
kubectl -n kube-public create role system:bootstrap-signer-clusterinfo --verb get --resource configmaps
kubectl -n kube-public create rolebinding kubeadm:bootstrap-signer-clusterinfo --role system:bootstrap-signer-clusterinfo --user system:anonymous
kubectl create clusterrolebinding kubeadm:kubelet-bootstrap --clusterrole system:node-bootstrapper --group system:bootstrappers
kubectl config set-credentials kubelet-bootstrap --token=${BOOTSTRAP_TOKEN} --kubeconfig=/etc/kubernetes/bootstrap.kubeconfig
systemctl start kubelet
sleep 10s

kubectl create clusterrolebinding kube-proxy:node-proxier --clusterrole system:node-proxier --serviceaccount system:kube-proxy
systemctl start kube-proxy
