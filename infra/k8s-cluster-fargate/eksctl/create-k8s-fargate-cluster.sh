#! /bin/bash

CLUSTER_NAME=$1
APPLICATION_NAME=$1

echo "CLUSTER_NAME: $CLUSTER_NAME"
echo "ACCOUNT_ID: $ACCOUNT_ID"
echo "AWS_PROFILE: $AWS_PROFILE"
echo "APPLICATION_NAME: $APPLICATION_NAME"
echo "LBC_VERSION: $LBC_VERSION"

eksctl create cluster --name $CLUSTER_NAME --region $AWS_REGION --fargate

eksctl create fargateprofile \
  --cluster ${CLUSTER_NAME} \
  --name $APPLICATION_NAME \
  --namespace $APPLICATION_NAME

eksctl utils associate-iam-oidc-provider \
    --region ${AWS_REGION} \
    --cluster ${CLUSTER_NAME} \
    --approve

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

eksctl create iamidentitymapping \
  --cluster $CLUSTER_NAME \
  --arn arn:aws:iam::$ACCOUNT_ID:role/$APPLICATION_NAME-kubectl-deploy-role \
  --group system:masters \
  --username $APPLICATION_NAME-role