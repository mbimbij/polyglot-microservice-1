#!/bin/bash

if [ -z $1 ]; then
  echo -e "usage:\n./create-infra.sh \$APPLICATION_NAME"
  exit 1
fi

APPLICATION_NAME=$1
PIPELINE_NAME=$APPLICATION_NAME-pipeline
KUBERNETES_CLUSTER_NAME=$APPLICATION_NAME
KAFKA_CLUSTER_NAME=$APPLICATION_NAME-kafka-cluster
source infra.env

# create cicd pipeline
aws cloudformation deploy  \
  --stack-name $PIPELINE_NAME  \
  --template-file pipeline/pipeline-stack.yml  \
  --capabilities CAPABILITY_NAMED_IAM  \
  --parameter-overrides ApplicationName=$APPLICATION_NAME \
    GithubRepo=$GITHUB_REPO \
    KubernetesClusterName=$KUBERNETES_CLUSTER_NAME \
    KafkaClusterName=$KAFKA_CLUSTER_NAME

# create k8s cluster
cd k8s-cluster-fargate/eksctl
./create-k8s-fargate-cluster.sh $KUBERNETES_CLUSTER_NAME
cd ../..

# create kafka cluster
privateSubnetIds=$(aws cloudformation list-exports --region eu-west-3 --query "Exports[?Name=='eksctl-$APPLICATION_NAME-cluster::SubnetsPrivate'].Value" --output text)
numberOfBrokerNodes=$(echo $privateSubnetIds | tr ',' '\n' | wc -l)
volumeSize=8
kafkaKmsId=$(aws kms list-aliases --query "Aliases[?AliasName=='alias/aws/kafka'].TargetKeyId" --output text)
kafkaKmsArn=$(aws kms describe-key --key-id $kafkaKmsId --query "KeyMetadata.Arn" --output text)
aws cloudformation deploy   \
  --stack-name $APPLICATION_NAME-kafka  \
  --template-file kafka/kafka-cfn.yml \
  --capabilities CAPABILITY_NAMED_IAM   \
  --parameter-overrides \
    Subnets=$privateSubnetIds \
    KMSKafkaArn=$kafkaKmsArn \
    NumberOfBrokerNodes=$numberOfBrokerNodes \
    KakfaClusterName=$KAFKA_CLUSTER_NAME \
    VolumeSize=$volumeSize