#!/bin/bash

if [ -z $1 ]; then
  echo -e "usage:\n./empty-s3-bucket.sh \$BUCKET_NAME"
  exit 1
fi

aws s3 rm s3://$AWS_REGION-$ACCOUNT_ID-$1-bucket-pipeline --recursive