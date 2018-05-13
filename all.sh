#!/bin/sh

set -ue

sh pre.sh
sh users.sh
sh mkdirs.sh
sh download.sh
sh pki.sh
sh kubeconfigs.sh
sh units.sh
sh start.sh
sh join.sh
sh weavenet.sh
sh coredns.sh
