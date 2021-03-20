#!/bin/sh

until microk8s.status --wait-ready; 
  do sleep 5; echo "waiting for worker status.."; 
done

echo "adding microk8s-cluster.${dns_zone} dns to CSR." 
sed -i 's@#MOREIPS@DNS.99 = microk8s-cluster.${dns_zone}\\n#MOREIPS\\n@g' /var/snap/microk8s/current/certs/csr.conf.template; 
echo 'done.'

sleep 10  
microk8s add-node --token ${cluster_token} --token-ttl ${cluster_token_ttl_seconds}
microk8s config > /client.config

echo "updating kubeconfig"
sed -i 's/127.0.0.1:16443/microk8s-cluster.${dns_zone}/g' /client.config
