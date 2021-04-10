#!/bin/bash

if [ -z $1 ]; then
  echo -e "usage:\n./create-infra.sh \$APPLICATION_NAME"
  exit 1
fi

export APPLICATION_NAME=$1
export KUBERNETES_CLUSTER_NAME=$APPLICATION_NAME
export KUBERNETES_STACK_NAME=eksctl-$APPLICATION_NAME-cluster
export KAFKA_CLUSTER_NAME=$APPLICATION_NAME-kafka-cluster
export KAFKA_STACK_NAME=$APPLICATION_NAME-kafka
source infra.env

# create k8s cluster
cd k8s-cluster-fargate/eksctl
./create-k8s-fargate-cluster.sh $APPLICATION_NAME
cd ../..

# create cicd pipelines
pipeline/create-microservice-pipeline.sh node-app
pipeline/create-microservice-pipeline.sh go-app

# create kafka cluster
privateSubnetIds=$(aws cloudformation list-exports --region $AWS_REGION --query "Exports[?Name=='$KUBERNETES_STACK_NAME::SubnetsPrivate'].Value" --output text)
numberOfBrokerNodes=$(echo $privateSubnetIds | tr ',' '\n' | wc -l)
volumeSize=8
kafkaKmsId=$(aws kms list-aliases --query "Aliases[?AliasName=='alias/aws/kafka'].TargetKeyId" --output text)
kafkaKmsArn=$(aws kms describe-key --key-id $kafkaKmsId --query "KeyMetadata.Arn" --output text)

echo "privateSubnetIds: $privateSubnetIds"
echo "numberOfBrokerNodes: $numberOfBrokerNodes"
echo "volumeSize: $volumeSize"
echo "kafkaKmsArn: $kafkaKmsArn"


aws cloudformation deploy   \
  --stack-name $KAFKA_STACK_NAME  \
  --template-file kafka/kafka-cfn.yml \
  --capabilities CAPABILITY_NAMED_IAM   \
  --parameter-overrides \
    KMSKafkaArn=$kafkaKmsArn \
    NumberOfBrokerNodes=$numberOfBrokerNodes \
    KakfaClusterName=$KAFKA_CLUSTER_NAME \
    KubernetesStackName=$KUBERNETES_STACK_NAME \
    VolumeSize=$volumeSize \
    BastionHostKeyName=$BASTION_HOST_KEY_NAME
