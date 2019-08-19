#!/bin/bash

CHOICE=${1}

case ${CHOICE} in
'ingress')
kubectl create secret generic weave-auth --from-file=/root/post-install/auth --namespace weave
kubectl create secret generic grafana-auth --from-file=/root/post-install/auth --namespace monitoring
kubectl create -f /root/post-install/dashboard-ingress.yml
kubectl create -f /root/post-install/weave-ingress.yml
kubectl create -f /root/post-install/grafana-ingress.yml
;;
'get-key')
POD=$(kubectl get pods -n kube-system | grep heketi | awk '{print $1}')
kubectl -n kube-system exec -it ${POD} -- cat /root/.ssh/id_rsa.pub
;;
'heketi-cluster')
if [ $# -eq 3 ];then
POD=$(kubectl get pods -n kube-system | grep heketi | awk '{print $1}')
kubectl -n kube-system exec -it ${POD} -- sed -i "s/node1/${2}/g" /etc/heketi/topology.json
kubectl -n kube-system exec -it ${POD} -- sed -i "s/node2/${3}/g" /etc/heketi/topology.json
kubectl -n kube-system exec -it ${POD} -- sed -i 's/\/dev\/vdb/\/dev\/xvdf/g' /etc/heketi/topology.json
kubectl -n kube-system exec -it ${POD} -- heketi-cli topology load --json=/etc/heketi/topology.json
echo ""
kubectl -n kube-system exec -it ${POD} -- heketi-cli cluster list
else
echo "Usage: ./deploy.sh heketi-cluster NODE1-PRIVATE-IP NODE2-PRIVATE-IP"
fi
;;
'deploy-app')
kubectl create -f /root/post-install/wordpress-application.yml
sleep 30
kubectl exec -it web-0 -- /root/deploy.sh
;;
*)
echo "Usage:"
echo "ingress        -- create ingress resources for weave ,dashboard and monitoring" 
echo "get-key        -- Get the public key for heketi container which must be distributed on the worker nodes before topology load" 
echo "deploy-app     -- Deploy wordpress website on the web container after it is initialized"
echo "heketi-cluster -- Bootstrap heketi cluster , after public key is distributed accross the worker nodes"
esac

