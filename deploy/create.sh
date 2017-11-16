#!/bin/sh

wkdir=$(pwd)
if [ ! -d "${wkdir}/.git" ]; then
  echo 'This script must be executed on local git repository root dir.' 1>&2
  exit 1
fi

if [ "${STACK_NAME}" = "" ]; then
  echo "'STACK_NAME' should be specified as an environment variable." 1>&2
  exit 1
fi
if [ "${S3_BUCKET_NAME}" = "" ]; then
  echo "'S3_BUCKET_NAME' should be specified as an environment variable." 1>&2
  exit 1
fi
if [ "${KEYPAIR_NAME}" = "" ]; then
  echo "'KEYPAIR_NAME' should be specified as an environment variable." 1>&2
  exit 1
fi

aws_region=${AWS_DEFAULT_REGION:-ap-northeast-1}
instance_type=${INSTANCE_TYPE:-t2.micro}

cat << EOT

[ Environment variables ]

STACK_NAME:    ${STACK_NAME}
AWS_REGION:    ${aws_region}
INSTANCE_TYPE: ${instance_type}
KEY_PAIR:      ${KEYPAIR_NAME}

EOT

\cp -f deploy/aws-cfn.yaml.template deploy/aws-cfn.yaml

# Upload templates to S3
aws s3 sync deploy/ s3://${S3_BUCKET_NAME}/ --delete --exclude "*.sh"

echo 'Creating a CloudFormation stack...'
aws cloudformation create-stack \
  --stack-name ${STACK_NAME} \
  --region ${aws_region} \
  --template-url https://${S3_BUCKET_NAME}.s3.amazonaws.com/aws-cfn.yaml \
  --parameters ParameterKey=InstanceType,ParameterValue="${instance_type}" \
               ParameterKey=KeyName,ParameterValue="${KEYPAIR_NAME}" \
  --capabilities CAPABILITY_NAMED_IAM

result=$(echo $?)
if [ "${result}" != "0" ]; then
  exit ${result}
fi

# Will wait for the stack to be provisioned successfully
echo 'Waiting for the stack to be created, this may take a few minutes...'
aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME}

result=$(echo $?)
exit ${result}
