#!/bin/bash

if [ -z $1 ]; then
  echo -e "usage:\n./delete-infra.sh \$APPLICATION_NAME"
  exit 1
fi

APPLICATION_NAME=$1
KAFKA_STACK_NAME=$APPLICATION_NAME-kafka
NETWORKING_STACK_NAME=$APPLICATION_NAME-network
source infra.env

# delete cicd pipeline
aws s3 rm s3://$AWS_REGION-$ACCOUNT_ID-node-app-bucket-pipeline --recursive
aws s3 rm s3://$AWS_REGION-$ACCOUNT_ID-go-app-bucket-pipeline --recursive
./scripts/empty-ecr-repository.sh $APPLICATION_NAME-node-app
./scripts/empty-ecr-repository.sh $APPLICATION_NAME-go-app
aws cloudformation delete-stack --stack-name $APPLICATION_NAME-node-app-pipeline
aws cloudformation delete-stack --stack-name $APPLICATION_NAME-go-app-pipeline

# delete kafka stack
aws cloudformation delete-stack --stack-name $KAFKA_STACK_NAME

# delete k8s stack
cd k8s-cluster-fargate/eksctl && ./delete-k8s-fargate-cluster.sh $APPLICATION_NAME

aws cloudformation delete-stack --stack-name $NETWORKING_STACK_NAME