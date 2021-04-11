#! /bin/bash

CLUSTER_NAME=$1
APPLICATION_NAME=$1

PRIVATE_SUBNETS=$2
PUBLIC_SUBNETS=$3

echo "CLUSTER_NAME: $CLUSTER_NAME"
echo "ACCOUNT_ID: $ACCOUNT_ID"
echo "AWS_PROFILE: $AWS_PROFILE"
echo "APPLICATION_NAME: $APPLICATION_NAME"
echo "LBC_VERSION: $LBC_VERSION"
echo "PRIVATE_SUBNETS: $PRIVATE_SUBNETS"
echo "PUBLIC_SUBNETS: $PUBLIC_SUBNETS"

eksctl create cluster --name $CLUSTER_NAME --region $AWS_REGION \
  --vpc-private-subnets=$PRIVATE_SUBNETS \
  --vpc-public-subnets=$PUBLIC_SUBNETS \
  --fargate --with-oidc

#eksctl create fargateprofile \
#  --cluster ${CLUSTER_NAME} \
#  --name $APPLICATION_NAME \
#  --namespace $APPLICATION_NAME

#eksctl utils associate-iam-oidc-provider \
#    --region ${AWS_REGION} \
#    --cluster ${CLUSTER_NAME} \
#    --approve

aws iam create-policy     --policy-name AWSLoadBalancerControllerIAMPolicy     --policy-document file://iam_policy.json

eksctl create iamserviceaccount \
  --cluster ${CLUSTER_NAME} \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

kubectl apply -k github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master

VPC_ID=$(aws eks describe-cluster \
                --name ${CLUSTER_NAME} \
                --query "cluster.resourcesVpcConfig.vpcId" \
                --output text)

helm repo add eks https://aws.github.io/eks-charts

helm upgrade -i aws-load-balancer-controller \
    eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=${CLUSTER_NAME} \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set image.tag="${LBC_VERSION}" \
    --set region=${AWS_REGION} \
    --set vpcId=${VPC_ID}