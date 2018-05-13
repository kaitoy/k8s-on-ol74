#!/bin/sh

set -eu

groupadd -r kubernetes
adduser -r -g kubernetes -M -s /sbin/nologin kubernetes

groupadd -r kube-admin
adduser -r -g kube-admin -M -s /sbin/nologin kube-admin

groupadd -r etcd
adduser -r -g etcd -M -s /sbin/nologin etcd
