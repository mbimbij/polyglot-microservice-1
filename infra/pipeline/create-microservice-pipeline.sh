#!/bin/bash

MICROSERVICE_NAME=$1

aws cloudformation deploy  \
  --stack-name $APPLICATION_NAME-$MICROSERVICE_NAME-pipeline \
  --template-file pipeline/pipeline-stack.yml  \
  --capabilities CAPABILITY_NAMED_IAM  \
  --parameter-overrides \
    ApplicationName=$MICROSERVICE_NAME \
    GithubRepo=$GITHUB_REPO \
    KubernetesClusterName=$KUBERNETES_CLUSTER_NAME \
    KafkaClusterName=$KAFKA_CLUSTER_NAME

eksctl create iamidentitymapping \
  --cluster $KUBERNETES_CLUSTER_NAME \
  --arn arn:aws:iam::$ACCOUNT_ID:role/$MICROSERVICE_NAME-kubectl-deploy-role \
  --group system:masters \
  --username $MICROSERVICE_NAME-kubectl-deploy-role