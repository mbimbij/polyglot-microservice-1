#!/bin/bash

MICROSERVICE_NAME=$1

STACK_NAME=$APPLICATION_NAME-$MICROSERVICE_NAME-pipeline
echo "STACK_NAME: $STACK_NAME"

aws cloudformation deploy  \
  --stack-name $STACK_NAME \
  --template-file pipeline/pipeline-stack.yml  \
  --capabilities CAPABILITY_NAMED_IAM  \
  --parameter-overrides \
    ApplicationName=$APPLICATION_NAME \
    MicroserviceName=$MICROSERVICE_NAME \
    GithubRepo=$GITHUB_REPO \
    KubernetesClusterName=$KUBERNETES_CLUSTER_NAME \
    KafkaClusterName=$KAFKA_CLUSTER_NAME

eksctl create iamidentitymapping \
  --cluster $KUBERNETES_CLUSTER_NAME \
  --arn arn:aws:iam::$ACCOUNT_ID:role/$MICROSERVICE_NAME-kubectl-deploy-role \
  --group system:masters \
  --username $MICROSERVICE_NAME-kubectl-deploy-role