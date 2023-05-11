#!/bin/bash

set -xe

aws_region="eu-west-1"
s3_name_prefix="pufferfish-tfstate-"
s3_name_parameter_path="/pufferfish/infra/tfbackend_s3_name"

# prevents reader opening after aws commands
export AWS_PAGER=""

if s3_name_param=$(aws ssm get-parameter --name $s3_name_parameter_path); then
  s3_name=$(echo "$s3_name_param" | jq -r ".Parameter.Value")
else
  s3_name="$s3_name_prefix$(echo $RANDOM | md5sum | head -c 20)"
  aws ssm put-parameter \
    --name $s3_name_parameter_path \
    --value "$s3_name" \
    --type String
fi

if [ "$(aws s3api list-buckets --query "Buckets[].Name" | jq "index(\"$s3_name\")")" == "null" ]; then
  aws s3api create-bucket \
    --bucket "$s3_name" \
    --region "$aws_region" \
    --create-bucket-configuration "{\"LocationConstraint\": \"$aws_region\"}"
fi

aws s3api put-bucket-versioning --bucket "$s3_name" --region $aws_region --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "$s3_name" \
  --server-side-encryption-configuration \
  '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "aws:kms"}}]}'

aws s3api put-bucket-tagging --bucket "$s3_name" --tagging 'TagSet=[{Key=ManagedBy,Value=BashScript}]'

ddb_table_name="$s3_name-locks"
if [ "$(aws dynamodb list-tables --query "TableNames" | jq "index(\"$ddb_table_name\")")" == "null" ]; then
  aws dynamodb create-table \
    --table-name "$ddb_table_name" \
    --region $aws_region \
    --billing-mode PAY_PER_REQUEST \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --tags Key=ManagedBy,Value=BashScript
fi
