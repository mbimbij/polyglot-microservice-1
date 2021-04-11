#!/bin/bash

if [ -z $1 ]; then
  echo -e "usage:\n./create-infra.sh \$APPLICATION_NAME"
  exit 1
fi

export APPLICATION_NAME=$1
export NETWORKING_STACK_NAME=$APPLICATION_NAME-network
export KUBERNETES_CLUSTER_NAME=$APPLICATION_NAME
export KUBERNETES_STACK_NAME=eksctl-$APPLICATION_NAME-cluster
export KAFKA_CLUSTER_NAME=$APPLICATION_NAME-kafka-cluster
export KAFKA_STACK_NAME=$APPLICATION_NAME-kafka
source infra.env

# create vpc and networking
aws cloudformation deploy \
  --stack-name $NETWORKING_STACK_NAME \
  --template-file networking/networking-cfn-template.yml \
  --capabilities CAPABILITY_NAMED_IAM

# create kafka cluster
nohup kafka/create-kafka-cluster.sh false &

# create k8s cluster
PRIVATE_SUBNETS=$(aws cloudformation list-exports --query "Exports[?Name=='$NETWORKING_STACK_NAME::SubnetsPrivate'].Value" --output text)
PUBLIC_SUBNETS=$(aws cloudformation list-exports --query "Exports[?Name=='$NETWORKING_STACK_NAME::SubnetsPublic'].Value" --output text)
cd k8s-cluster-fargate/eksctl
echo "PRIVATE_SUBNETS: $PRIVATE_SUBNETS"
echo "PUBLIC_SUBNETS: $PUBLIC_SUBNETS"
./create-k8s-fargate-cluster.sh $APPLICATION_NAME $PRIVATE_SUBNETS $PUBLIC_SUBNETS
cd ../..

# create cicd pipelines
nohup pipeline/create-microservice-pipeline.sh node-app &
nohup pipeline/create-microservice-pipeline.sh go-app &

wait
echo "kafka, k8 clusters, microservices pipelines creation done"

echo "##############################################################################"
echo "updating kafka sg: adding eks security group as an authorized ingress"
echo "##############################################################################"
nohup kafka/create-kafka-cluster.sh true &
#eksSecurityGroupId=$(aws cloudformation list-exports --region $AWS_REGION --query "Exports[?Name=='$KUBERNETES_STACK_NAME::ClusterSecurityGroupId'].Value" --output text)
#kafkaClusterArn=$(aws kafka list-clusters --query "ClusterInfoList[?ClusterName=='$KAFKA_CLUSTER_NAME'].ClusterArn" --output text)
#kafkaClusterSecurityGroup=$(aws kafka describe-cluster --cluster-arn $kafkaClusterArn --query "ClusterInfo.BrokerNodeGroupInfo.SecurityGroups[]" --output text)
#aws ec2 authorize-security-group-ingress --group-id $kafkaClusterSecurityGroup --source-group $eksSecurityGroupId --port 9092 --protocol tcp

echo "##############################################################################"
echo "creating kafka topic 'test'"
echo "##############################################################################"
kafkaClusterArn=$(aws kafka list-clusters --query "ClusterInfoList[?ClusterName=='$KAFKA_CLUSTER_NAME'].ClusterArn" --output text)
kafkaClusterBootstrapBrokers=$(aws kafka get-bootstrap-brokers --cluster-arn $kafkaClusterArn --query "BootstrapBrokerString" --output text | awk -F ',' '{print $1}')
bastionHostPublicDnsName=$(aws cloudformation describe-stacks --stack-name $KAFKA_STACK_NAME --query "Stacks[].Outputs[?OutputKey=='BastionHostPublicDnsName'][].OutputValue" --output text)
ssh -o StrictHostKeyChecking=no ubuntu@$bastionHostPublicDnsName "./kafka_2.13-2.7.0/bin/kafka-topics.sh --bootstrap-server $kafkaClusterBootstrapBrokers --create --topic test"
