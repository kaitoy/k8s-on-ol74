#!/bin/sh

set -ue

source ./env.sh

KCONFIG=/etc/kubernetes/kube-controller-manager.kubeconfig
KUSER="system:kube-controller-manager"
kubectl config set-cluster ${CLUSTER_NAME} --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 --kubeconfig=${KCONFIG}
kubectl config set-credentials ${KUSER} --client-certificate=/etc/kubernetes/pki/kube-controller-manager.crt --client-key=/etc/kubernetes/pki/kube-controller-manager.key --embed-certs=true --kubeconfig=${KCONFIG}
kubectl config set-context ${KUSER}@${CLUSTER_NAME} --cluster=${CLUSTER_NAME} --user=${KUSER} --kubeconfig=${KCONFIG}
kubectl config use-context ${KUSER}@${CLUSTER_NAME} --kubeconfig=${KCONFIG}
chown kubernetes:kubernetes ${KCONFIG}
chmod 0600 ${KCONFIG}

KCONFIG=/etc/kubernetes/kube-scheduler.kubeconfig
KUSER="system:kube-scheduler"
kubectl config set-cluster ${CLUSTER_NAME} --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 --kubeconfig=${KCONFIG}
kubectl config set-credentials ${KUSER} --client-certificate=/etc/kubernetes/pki/kube-scheduler.crt --client-key=/etc/kubernetes/pki/kube-scheduler.key --embed-certs=true --kubeconfig=${KCONFIG}
kubectl config set-context ${KUSER}@${CLUSTER_NAME} --cluster=${CLUSTER_NAME} --user=${KUSER} --kubeconfig=${KCONFIG}
kubectl config use-context ${KUSER}@${CLUSTER_NAME} --kubeconfig=${KCONFIG}
chown kubernetes:kubernetes ${KCONFIG}
chmod 0600 ${KCONFIG}

KCONFIG=/etc/kubernetes/admin.kubeconfig
KUSER="kubernetes-admin"
kubectl config set-cluster ${CLUSTER_NAME} --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 --kubeconfig=${KCONFIG}
kubectl config set-credentials ${KUSER} --client-certificate=/etc/kubernetes/pki/admin.crt --client-key=/etc/kubernetes/pki/admin.key --embed-certs=true --kubeconfig=${KCONFIG}
kubectl config set-context ${KUSER}@${CLUSTER_NAME} --cluster=${CLUSTER_NAME} --user=${KUSER} --kubeconfig=${KCONFIG}
kubectl config use-context ${KUSER}@${CLUSTER_NAME} --kubeconfig=${KCONFIG}
chown kube-admin:kube-admin ${KCONFIG}
chmod 0600 ${KCONFIG}
ln -s ${KCONFIG} ~/.kube/config

KCONFIG="/etc/kubernetes/bootstrap.kubeconfig"
KUSER="kubelet-bootstrap"
kubectl config set-cluster ${CLUSTER_NAME} --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 --kubeconfig=${KCONFIG}
kubectl config set-context ${KUSER}@${CLUSTER_NAME} --cluster=${CLUSTER_NAME} --user=${KUSER} --kubeconfig=${KCONFIG}
kubectl config use-context ${KUSER}@${CLUSTER_NAME} --kubeconfig=${KCONFIG}
chown kubernetes:kubernetes ${KCONFIG}
chmod 0600 ${KCONFIG}

KCONFIG="/etc/kubernetes/kube-proxy.kubeconfig"
KUSER="system:kube-proxy"
kubectl config set-cluster ${CLUSTER_NAME} --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 --kubeconfig=${KCONFIG}
kubectl config set-credentials ${KUSER} --client-certificate=/etc/kubernetes/pki/kube-proxy.crt --client-key=/etc/kubernetes/pki/kube-proxy.key --embed-certs=true --kubeconfig=${KCONFIG}
kubectl config set-context ${KUSER}@${CLUSTER_NAME} --cluster=${CLUSTER_NAME} --user=${KUSER} --kubeconfig=${KCONFIG}
kubectl config use-context ${KUSER}@${CLUSTER_NAME} --kubeconfig=${KCONFIG}
chown kubernetes:kubernetes ${KCONFIG}
chmod 0600 ${KCONFIG}
