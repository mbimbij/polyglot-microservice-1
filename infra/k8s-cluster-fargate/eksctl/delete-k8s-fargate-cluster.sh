#! /bin/bash

delete-ingresses() {
  for ns in $(kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
  do 
    kubectl delete ingress -n $ns --all
  done
}

delete-ingresses
eksctl delete cluster $1
