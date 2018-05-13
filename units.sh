#!/bin/sh

set -ue

source ./env.sh

cat > /etc/systemd/system/etcd.service << EOF
[Unit]
Description=etcd
Documentation=https://coreos.com/etcd/docs/latest/
After=network.target

[Service]
Type=notify
NotifyAccess=all
User=etcd
Group=etcd
ExecStart=/usr/bin/etcd \\
  --name ${ETCD_MEMBER_NAME} \\
  --listen-client-urls https://${MASTER_IP}:2379 \\
  --advertise-client-urls https://${MASTER_IP}:2379 \\
  --data-dir=/var/lib/etcd \\
  --cert-file=/etc/kubernetes/pki/etcd.crt \\
  --key-file=/etc/kubernetes/pki/etcd.key \\
  --peer-cert-file=/etc/kubernetes/pki/etcd-peer.crt \\
  --peer-key-file=/etc/kubernetes/pki/etcd-peer.key \\
  --trusted-ca-file=/etc/kubernetes/pki/etcd-ca.crt \\
  --peer-trusted-ca-file=/etc/kubernetes/pki/etcd-ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${MASTER_IP}:2380 \\
  --listen-peer-urls https://${MASTER_IP}:2380 \\
  --initial-cluster-token ${ETCD_CLUSTER_TOKEN} \\
  --initial-cluster ${ETCD_MEMBER_NAME}=https://${MASTER_IP}:2380 \\
  --initial-cluster-state new
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable etcd

cat > /etc/kubernetes/encryption.conf << EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
    - secrets
    providers:
    - aescbc:
        keys:
        - name: key1
          secret: ${SECRET_ENC_KEY}
    - identity: {}
EOF
cat > /etc/kubernetes/audit-policy.conf << EOF
apiVersion: audit.k8s.io/v1beta1
kind: Policy
# Don't generate audit events for all requests in RequestReceived stage.
omitStages:
  - "RequestReceived"
rules:
  # Log pod changes at RequestResponse level
  - level: RequestResponse
    resources:
    - group: ""
      # Resource "pods" doesn't match requests to any subresource of pods,
      # which is consistent with the RBAC policy.
      resources: ["pods"]
  # Log "pods/log", "pods/status" at Metadata level
  - level: Metadata
    resources:
    - group: ""
      resources: ["pods/log", "pods/status"]

  # Don't log requests to a configmap called "controller-leader"
  - level: None
    resources:
    - group: ""
      resources: ["configmaps"]
      resourceNames: ["controller-leader"]

  # Don't log watch requests by the "system:kube-proxy" on endpoints or services
  - level: None
    users: ["system:kube-proxy"]
    verbs: ["watch"]
    resources:
    - group: "" # core API group
      resources: ["endpoints", "services"]

  # Don't log authenticated requests to certain non-resource URL paths.
  - level: None
    userGroups: ["system:authenticated"]
    nonResourceURLs:
    - "/api*" # Wildcard matching.
    - "/version"

  # Log the request body of configmap changes in kube-system.
  - level: Request
    resources:
    - group: "" # core API group
      resources: ["configmaps"]
    # This rule only applies to resources in the "kube-system" namespace.
    # The empty string "" can be used to select non-namespaced resources.
    namespaces: ["kube-system"]

  # Log configmap and secret changes in all other namespaces at the Metadata level.
  - level: Metadata
    resources:
    - group: "" # core API group
      resources: ["secrets", "configmaps"]

  # Log all other resources in core and extensions at the Request level.
  - level: Request
    resources:
    - group: "" # core API group
    - group: "extensions" # Version of group should NOT be included.

  # A catch-all rule to log all other requests at the Metadata level.
  - level: Metadata
    # Long-running requests like watches that fall under this rule will not
    # generate an audit event in RequestReceived.
    omitStages:
      - "RequestReceived"
EOF
cat > /etc/systemd/system/kube-apiserver.service << EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes
After=network.target

[Service]
User=kubernetes
Group=kubernetes
ExecStart=/usr/bin/kube-apiserver \\
  --feature-gates=RotateKubeletServerCertificate=true \\
  --apiserver-count=1 \\
  --allow-privileged=true \\
  --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,NodeRestriction,DenyEscalatingExec,StorageObjectInUseProtection \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --advertise-address=${MASTER_IP} \\
  --client-ca-file=/etc/kubernetes/pki/ca.crt \\
  --etcd-cafile=/etc/kubernetes/pki/etcd-ca.crt \\
  --etcd-certfile=/etc/kubernetes/pki/etcd-client.crt \\
  --etcd-keyfile=/etc/kubernetes/pki/etcd-client.key \\
  --etcd-servers=https://${MASTER_IP}:2379 \\
  --service-account-key-file=/etc/kubernetes/pki/kube-controller-manager.pub \\
  --service-cluster-ip-range=${SERVICE_CLUSTER_IP_RANGE} \\
  --tls-cert-file=/etc/kubernetes/pki/kube-apiserver.crt \\
  --tls-private-key-file=/etc/kubernetes/pki/kube-apiserver.key \\
  --kubelet-certificate-authority=/etc/kubernetes/pki/ca.crt \\
  --enable-bootstrap-token-auth=true \\
  --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt \\
  --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key \\
  --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname \\
  --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt \\
  --requestheader-username-headers=X-Remote-User \\
  --requestheader-group-headers=X-Remote-Group \\
  --requestheader-allowed-names=front-proxy-client \\
  --requestheader-extra-headers-prefix=X-Remote-Extra- \\
  --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt \\
  --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key \\
  --experimental-encryption-provider-config=/etc/kubernetes/encryption.conf \\
  --v=2 \\
  --tls-min-version=VersionTLS12 \\
  --tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 \\
  --anonymous-auth=false \\
  --audit-log-format=json \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/kubernetes/kube-audit.log \\
  --audit-policy-file=/etc/kubernetes/audit-policy.conf
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable kube-apiserver

cat > /etc/systemd/system/kube-controller-manager.service << EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
After=network.target

[Service]
User=kubernetes
Group=kubernetes
ExecStart=/usr/bin/kube-controller-manager \\
  --feature-gates=RotateKubeletServerCertificate=true \\
  --kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \\
  --bind-address=0.0.0.0 \\
  --controllers=*,bootstrapsigner,tokencleaner \\
  --service-account-private-key-file=/etc/kubernetes/pki/kube-controller-manager.key \\
  --allocate-node-cidrs=true \\
  --cluster-cidr=${CLUSTER_CIDR} \\
  --node-cidr-mask-size=24 \\
  --cluster-name=${CLUSTER_NAME} \\
  --service-cluster-ip-range=${SERVICE_CLUSTER_IP_RANGE} \\
  --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt \\
  --cluster-signing-key-file=/etc/kubernetes/pki/ca.key \\
  --root-ca-file=/etc/kubernetes/pki/ca.crt \\
  --use-service-account-credentials=true \\
  --v=2 \\
  --experimental-cluster-signing-duration=8760h0m0s
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable kube-controller-manager

cat > /etc/kubernetes/kube-scheduler.conf << EOF
kind: KubeSchedulerConfiguration
apiVersion: componentconfig/v1alpha1
featureGates:
  RotateKubeletServerCertificate: true
healthzBindAddress: "0.0.0.0"
clientConnection:
  kubeconfig: "/etc/kubernetes/kube-scheduler.kubeconfig"
EOF
cat > /etc/systemd/system/kube-scheduler.service << EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
After=network.target

[Service]
User=kubernetes
Group=kubernetes
ExecStart=/usr/bin/kube-scheduler \\
  --config=/etc/kubernetes/kube-scheduler.conf \\
  --v=2
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable kube-scheduler

cat > /etc/kubernetes/kubelet.conf << EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
featureGates:
  RotateKubeletServerCertificate: true
address: "0.0.0.0"
staticPodPath: "/etc/kubernetes/manifests"
clusterDNS: ["${DNS_SERVER_IP}"]
clusterDomain: "${DNS_DOMAIN}"
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: "5m0s"
    cacheUnauthorizedTTL: "30s"
authentication:
  x509:
    clientCAFile: "/etc/kubernetes/pki/ca.crt"
  webhook:
    enabled: false
    cacheTTL: "0s"
  anonymous:
    enabled: false
cgroupDriver: "cgroupfs"
tlsMinVersion: "VersionTLS12"
tlsCipherSuites:
- "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
- "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
- "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
- "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
readOnlyPort: 0
# port: 10250
# containerLogMaxSize: "10Mi"
# containerLogMaxFiles: 5
# evictionHard:
#   imagefs.available: "15%"
#   memory.available: "100Mi"
#   nodefs.available: "10%"
#   nodefs.inodesFree: "5%"
# evictionMaxPodGracePeriod: 0
# evictionPressureTransitionPeriod: "5m0s"
# fileCheckFrequency: "20s"
# imageGCHighThresholdPercent: 85
# imageGCLowThresholdPercent: 80
# maxOpenFiles: 1000000
# maxPods: 110
# imageMinimumGCAge: "2m0s"
# nodeStatusUpdateFrequency: "10s"
# runtimeRequestTimeout: "2m0s"
# streamingConnectionIdleTimeout: "4h0m0s"
# syncFrequency: "1m0s"
# volumeStatsAggPeriod: "1m0s"
EOF
cat > /etc/systemd/system/kubelet.service << EOF
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=docker.service
Requires=docker.service

[Service]
User=root
Group=root
ExecStart=/usr/bin/kubelet \\
  --allow-privileged=true \\
  --config=/etc/kubernetes/kubelet.conf \\
  --bootstrap-kubeconfig=/etc/kubernetes/bootstrap.kubeconfig \\
  --kubeconfig=/etc/kubernetes/kubelet.kubeconfig \\
  --network-plugin=cni \\
  --cni-conf-dir=/etc/cni/net.d \\
  --cni-bin-dir=/opt/cni/bin \\
  --cert-dir=/etc/kubernetes/pki \\
  --rotate-certificates=true \\
  --v=2 \\
  --pod-infra-container-image=${PAUSE_IMAGE}
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable kubelet

cat > /etc/kubernetes/kube-proxy.conf << EOF
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
featureGates:
  RotateKubeletServerCertificate: true
bindAddress: "0.0.0.0"
clientConnection:
  kubeconfig: "/etc/kubernetes/kube-proxy.kubeconfig"
clusterCIDR: "${CLUSTER_CIDR}"
EOF
cat > /etc/systemd/system/kube-proxy.service << EOF
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes
After=network.target

[Service]
User=root
Group=root
ExecStart=/usr/bin/kube-proxy \\
  --config=/etc/kubernetes/kube-proxy.conf \\
  --v=2
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable kube-proxy

systemctl daemon-reload
