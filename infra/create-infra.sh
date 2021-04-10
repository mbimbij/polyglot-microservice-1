#!/bin/bash

if [ -z $1 ]; then
  echo -e "usage:\n./create-infra.sh \$APPLICATION_NAME"
  exit 1
fi

APPLICATION_NAME=$1
PIPELINE_NAME=$APPLICATION_NAME-pipeline
KUBERNETES_CLUSTER_NAME=$APPLICATION_NAME
KUBERNETES_STACK_NAME=eksctl-$APPLICATION_NAME-cluster
KAFKA_CLUSTER_NAME=$APPLICATION_NAME-kafka-cluster
KAFKA_STACK_NAME=$APPLICATION_NAME-kafka
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
./create-k8s-fargate-cluster.sh $APPLICATION_NAME
cd ../..

# create kafka cluster
bastionHostSubnetId=$(aws cloudformation list-exports --region $AWS_REGION --query "Exports[?Name=='$KUBERNETES_STACK_NAME::SubnetsPublic'].Value" --output text | awk -F ',' '{print $1}')
privateSubnetIds=$(aws cloudformation list-exports --region $AWS_REGION --query "Exports[?Name=='$KUBERNETES_STACK_NAME::SubnetsPrivate'].Value" --output text)
numberOfBrokerNodes=$(echo $privateSubnetIds | tr ',' '\n' | wc -l)
volumeSize=8
kafkaKmsId=$(aws kms list-aliases --query "Aliases[?AliasName=='alias/aws/kafka'].TargetKeyId" --output text)
kafkaKmsArn=$(aws kms describe-key --key-id $kafkaKmsId --query "KeyMetadata.Arn" --output text)

echo "bastionHostSubnetId: $bastionHostSubnetId"
echo "privateSubnetIds: $privateSubnetIds"
echo "numberOfBrokerNodes: $numberOfBrokerNodes"
echo "volumeSize: $volumeSize"
echo "kafkaKmsId: $kafkaKmsId"
echo "kafkaKmsArn: $kafkaKmsArn"


aws cloudformation deploy   \
  --stack-name $KAFKA_STACK_NAME  \
  --template-file kafka/kafka-cfn.yml \
  --capabilities CAPABILITY_NAMED_IAM   \
  --parameter-overrides \
    Subnets=$privateSubnetIds \
    KMSKafkaArn=$kafkaKmsArn \
    NumberOfBrokerNodes=$numberOfBrokerNodes \
    KakfaClusterName=$KAFKA_CLUSTER_NAME \
    VolumeSize=$volumeSize \
    BastionHostSubnetId=$bastionHostSubnetId  \
    BastionHostKeyName=$BASTION_HOST_KEY_NAME

# modifying kafka security group
eksSecurityGroupId=$(aws cloudformation list-exports --region $AWS_REGION --query "Exports[?Name=='$KUBERNETES_STACK_NAME::ClusterSecurityGroupId'].Value" --output text)
kafkaClusterArn=$(aws kafka list-clusters --query "ClusterInfoList[?ClusterName=='$KAFKA_CLUSTER_NAME'].ClusterArn" --output text)
kafkaClusterSecurityGroup=$(aws kafka describe-cluster --cluster-arn $kafkaClusterArn --query "ClusterInfo.BrokerNodeGroupInfo.SecurityGroups[]" --output text)
bastionHostSecurityGroupId=$(aws cloudformation describe-stacks --stack-name $KAFKA_STACK_NAME --query "Stacks[].Outputs[?OutputKey=='BastionHostSecurityGroupId'].OutputValue[]" --output text)
aws ec2 authorize-security-group-ingress --group-id $kafkaClusterSecurityGroup --source-group $eksSecurityGroupId --port 9092 --protocol tcp
aws ec2 authorize-security-group-ingress --group-id $kafkaClusterSecurityGroup --source-group $bastionHostSecurityGroupId --port 9092 --protocol tcp
