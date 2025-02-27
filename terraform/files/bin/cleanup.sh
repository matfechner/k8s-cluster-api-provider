#!/bin/bash
# cleanup.sh

export KUBECONFIG=~/.kube/config
kubectl config use-context kind-kind
CLUSTERS=$(kubectl get clusters | grep -v '^NAME' | awk '{ print $1; }')
echo "Deleting all clusters: $CLUSTERS"
echo "Hit ^C to interrupt"
sleep 3
#for file in *-config.yaml; do cluster="${file%-config.yaml}"
for cluster in $CLUSTERS; do
	~/bin/delete_cluster.sh "$cluster"
done
kubectl get clusters
