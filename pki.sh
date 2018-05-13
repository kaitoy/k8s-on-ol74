#!/bin/sh

set -eu

source ./env.sh

cat > /etc/kubernetes/pki/openssl.cnf << EOF
[ req ]
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_ca ]
basicConstraints = critical, CA:TRUE
keyUsage = critical, digitalSignature, keyEncipherment, keyCertSign
[ v3_req_client ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
[ v3_req_apiserver ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names_cluster
[ v3_req_etcd ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names_etcd
[ alt_names_cluster ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
DNS.5 = k8s-controller
IP.1 = ${MASTER_IP}
IP.2 = ${K8S_SERVICE_IP}
[ alt_names_etcd ]
DNS.1 = k8s-controller
IP.1 = ${MASTER_IP}
EOF

openssl ecparam -name secp521r1 -genkey -noout -out /etc/kubernetes/pki/ca.key
chown kubernetes:kubernetes /etc/kubernetes/pki/ca.key
chmod 0600 /etc/kubernetes/pki/ca.key
openssl req -x509 -new -sha256 -nodes -key /etc/kubernetes/pki/ca.key -days $CA_DAYS -out /etc/kubernetes/pki/ca.crt -subj "/CN=kubernetes-ca"  -extensions v3_ca -config /etc/kubernetes/pki/openssl.cnf

openssl ecparam -name secp521r1 -genkey -noout -out /etc/kubernetes/pki/kube-apiserver.key
chown kubernetes:kubernetes /etc/kubernetes/pki/kube-apiserver.key
chmod 0600 /etc/kubernetes/pki/kube-apiserver.key
openssl req -new -sha256 -key /etc/kubernetes/pki/kube-apiserver.key -subj "/CN=kube-apiserver" | openssl x509 -req -sha256 -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out /etc/kubernetes/pki/kube-apiserver.crt -days $APISERVER_DAYS -extensions v3_req_apiserver -extfile /etc/kubernetes/pki/openssl.cnf

openssl ecparam -name secp521r1 -genkey -noout -out /etc/kubernetes/pki/apiserver-kubelet-client.key
chown kubernetes:kubernetes /etc/kubernetes/pki/apiserver-kubelet-client.key
chmod 0600 /etc/kubernetes/pki/apiserver-kubelet-client.key
openssl req -new -key /etc/kubernetes/pki/apiserver-kubelet-client.key -subj "/CN=kube-apiserver-kubelet-client/O=system:masters" | openssl x509 -req -sha256 -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out /etc/kubernetes/pki/apiserver-kubelet-client.crt -days $APISERVER_KUBELET_CLIENT_DAYS -extensions v3_req_client -extfile /etc/kubernetes/pki/openssl.cnf

openssl ecparam -name secp521r1 -genkey -noout -out /etc/kubernetes/pki/admin.key
chown kube-admin:kube-admin /etc/kubernetes/pki/admin.key
chmod 0600 /etc/kubernetes/pki/admin.key
openssl req -new -key /etc/kubernetes/pki/admin.key -subj "/CN=kubernetes-admin/O=system:masters" | openssl x509 -req -sha256 -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out /etc/kubernetes/pki/admin.crt -days $ADMIN_DAYS -extensions v3_req_client -extfile /etc/kubernetes/pki/openssl.cnf

openssl ecparam -name secp521r1 -genkey -noout -out /etc/kubernetes/pki/kube-controller-manager.key
openssl ec -in /etc/kubernetes/pki/kube-controller-manager.key -outform PEM -pubout -out /etc/kubernetes/pki/kube-controller-manager.pub
chown kubernetes:kubernetes /etc/kubernetes/pki/kube-controller-manager.key
chmod 0600 /etc/kubernetes/pki/kube-controller-manager.key
openssl req -new -sha256 -key /etc/kubernetes/pki/kube-controller-manager.key -subj "/CN=system:kube-controller-manager" | openssl x509 -req -sha256 -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out /etc/kubernetes/pki/kube-controller-manager.crt -days $CONTROLLER_MANAGER_DAYS -extensions v3_req_client -extfile /etc/kubernetes/pki/openssl.cnf

openssl ecparam -name secp521r1 -genkey -noout -out /etc/kubernetes/pki/kube-scheduler.key
chown kubernetes:kubernetes /etc/kubernetes/pki/kube-scheduler.key
chmod 0600 /etc/kubernetes/pki/kube-scheduler.key
openssl req -new -sha256 -key /etc/kubernetes/pki/kube-scheduler.key -subj "/CN=system:kube-scheduler" | openssl x509 -req -sha256 -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out /etc/kubernetes/pki/kube-scheduler.crt -days $SCHEDULER_DAYS -extensions v3_req_client -extfile /etc/kubernetes/pki/openssl.cnf

openssl ecparam -name secp521r1 -genkey -noout -out /etc/kubernetes/pki/kube-proxy.key
chown kubernetes:kubernetes /etc/kubernetes/pki/kube-proxy.key
chmod 0600 /etc/kubernetes/pki/kube-proxy.key
openssl req -new -sha256 -key /etc/kubernetes/pki/kube-proxy.key -subj "/CN=system:kube-proxy" | openssl x509 -req -sha256 -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out /etc/kubernetes/pki/kube-proxy.crt -days $PROXY_DAYS -extensions v3_req_client -extfile /etc/kubernetes/pki/openssl.cnf

openssl ecparam -name secp521r1 -genkey -noout -out /etc/kubernetes/pki/front-proxy-ca.key
chown kubernetes:kubernetes /etc/kubernetes/pki/front-proxy-ca.key
chmod 0600 /etc/kubernetes/pki/front-proxy-ca.key
openssl req -x509 -new -sha256 -nodes -key /etc/kubernetes/pki/front-proxy-ca.key -days $FRONT_PROXY_CA_DAYS -out /etc/kubernetes/pki/front-proxy-ca.crt -subj "/CN=front-proxy-ca" -extensions v3_ca -config /etc/kubernetes/pki/openssl.cnf

openssl ecparam -name secp521r1 -genkey -noout -out /etc/kubernetes/pki/front-proxy-client.key
chown kubernetes:kubernetes /etc/kubernetes/pki/front-proxy-client.key
chmod 0600 /etc/kubernetes/pki/front-proxy-client.key
openssl req -new -sha256 -key /etc/kubernetes/pki/front-proxy-client.key -subj "/CN=front-proxy-client" | openssl x509 -req -sha256 -CA /etc/kubernetes/pki/front-proxy-ca.crt -CAkey /etc/kubernetes/pki/front-proxy-ca.key -CAcreateserial -out /etc/kubernetes/pki/front-proxy-client.crt -days $FRONT_PROXY_CLIENT_DAYS -extensions v3_req_client -extfile /etc/kubernetes/pki/openssl.cnf

openssl ecparam -name secp521r1 -genkey -noout -out /etc/kubernetes/pki/etcd-ca.key
chown etcd:etcd /etc/kubernetes/pki/etcd-ca.key
chmod 0600 /etc/kubernetes/pki/etcd-ca.key
openssl req -x509 -new -sha256 -nodes -key /etc/kubernetes/pki/etcd-ca.key -days $ETCD_CA_DAYS -out /etc/kubernetes/pki/etcd-ca.crt -subj "/CN=etcd-ca" -extensions v3_ca -config /etc/kubernetes/pki/openssl.cnf

openssl ecparam -name secp521r1 -genkey -noout -out /etc/kubernetes/pki/etcd.key
chown etcd:etcd /etc/kubernetes/pki/etcd.key
chmod 0600 /etc/kubernetes/pki/etcd.key
openssl req -new -sha256 -key /etc/kubernetes/pki/etcd.key -subj "/CN=etcd" | openssl x509 -req -sha256 -CA /etc/kubernetes/pki/etcd-ca.crt -CAkey /etc/kubernetes/pki/etcd-ca.key -CAcreateserial -out /etc/kubernetes/pki/etcd.crt -days $ETCD_DAYS -extensions v3_req_etcd -extfile /etc/kubernetes/pki/openssl.cnf

openssl ecparam -name secp521r1 -genkey -noout -out /etc/kubernetes/pki/etcd-client.key
chown kubernetes:kubernetes /etc/kubernetes/pki/etcd-client.key
chmod 0600 /etc/kubernetes/pki/etcd-client.key
openssl req -new -sha256 -key /etc/kubernetes/pki/etcd-client.key -subj "/CN=kube-apiserver" | openssl x509 -req -sha256 -CA /etc/kubernetes/pki/etcd-ca.crt -CAkey /etc/kubernetes/pki/etcd-ca.key -CAcreateserial -out /etc/kubernetes/pki/etcd-client.crt -days $ETCD_CLIENT_DAYS -extensions v3_req_client -extfile /etc/kubernetes/pki/openssl.cnf

openssl ecparam -name secp521r1 -genkey -noout -out /etc/kubernetes/pki/etcd-peer.key
chown etcd:etcd /etc/kubernetes/pki/etcd-peer.key
chmod 0600 /etc/kubernetes/pki/etcd-peer.key
openssl req -new -sha256 -key /etc/kubernetes/pki/etcd-peer.key -subj "/CN=etcd-peer" | openssl x509 -req -sha256 -CA /etc/kubernetes/pki/etcd-ca.crt -CAkey /etc/kubernetes/pki/etcd-ca.key -CAcreateserial -out /etc/kubernetes/pki/etcd-peer.crt -days $ETCD_PEER_DAYS -extensions v3_req_etcd -extfile /etc/kubernetes/pki/openssl.cnf
