#!/bin/bash

if [ -z $1 ]; then
  echo -e "usage:\n./delete-infra.sh \$APPLICATION_NAME"
  exit 1
fi

APPLICATION_NAME=$1
KUBERNETES_CLUSTER_NAME=$APPLICATION_NAME
KUBERNETES_STACK_NAME=eksctl-$APPLICATION_NAME-cluster
KAFKA_CLUSTER_NAME=$APPLICATION_NAME-kafka-cluster
KAFKA_STACK_NAME=$APPLICATION_NAME-kafka
source infra.env

# delete cicd pipeline
aws s3 rm s3://$AWS_REGION-$ACCOUNT_ID-node-app-bucket-pipeline --recursive
aws s3 rm s3://$AWS_REGION-$ACCOUNT_ID-go-app-bucket-pipeline --recursive
aws cloudformation delete-stack --stack-name $APPLICATION_NAME-node-app-pipeline
aws cloudformation delete-stack --stack-name $APPLICATION_NAME-go-app-pipeline

# delete kafka stack
aws cloudformation delete-stack --stack-name $KAFKA_STACK_NAME

# delete k8s stack
cd k8s-cluster-fargate/eksctl
./delete-k8s-fargate-cluster.sh $APPLICATION_NAME