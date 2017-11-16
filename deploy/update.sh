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
if [ "${HUBOT_SLACK_TOKEN}" = "" ]; then
  echo "'HUBOT_SLACK_TOKEN' should be specified as an environment variable." 1>&2
  exit 1
fi
if [ "${HUBOT_SLACK_TEAM}" = "" ]; then
  echo "'HUBOT_SLACK_TEAM' should be specified as an environment variable." 1>&2
  exit 1
fi

aws_region=${AWS_DEFAULT_REGION:-ap-northeast-1}
hubot_name=${HUBOT_SLACK_BOTNAME:-hubot}

cat << EOT

[ Environment variables ]

STACK_NAME:        ${STACK_NAME}
AWS_REGION:        ${aws_region}

HUBOT_SLACK_TOKEN: ${HUBOT_SLACK_TOKEN}
HUBOT_SLACK_TEAM:  ${HUBOT_SLACK_TEAM}
HUBOT_SLACK_BOT:   ${hubot_name}

EOT

# Build a docker image
aws_account_id=$( aws sts get-caller-identity --query "Account" --output text )
ecr_registory=${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com
docker_image_tag=$( date +%Y%m%d%h%M )
docker build -t ${ecr_registory}/hubot:${docker_image_tag} .

# Docker login & push the docker image
aws ecr get-login --no-include-email | sh -
docker push ${ecr_registory}/hubot:${docker_image_tag}

# Replace the docker image
\cp -f deploy/aws-cfn.yaml.template deploy/aws-cfn.yaml
sed -i -e 's/dockercloud\/hello-world/'${ecr_registory}'\/hubot:'${docker_image_tag}'/g' \
    deploy/aws-cfn.yaml
sed -i -e 's/@token/'${HUBOT_SLACK_TOKEN}'/g' deploy/aws-cfn.yaml
sed -i -e 's/@team/'${HUBOT_SLACK_TEAM}'/g' deploy/aws-cfn.yaml
sed -i -e 's/@hubot/'${hubot_name}'/g' deploy/aws-cfn.yaml

# Upload templates to S3
aws s3 sync deploy/ s3://${S3_BUCKET_NAME}/ --delete --exclude "*.sh"

echo 'Updating a specified CloudFormation stack...'
aws cloudformation update-stack \
  --stack-name ${STACK_NAME} \
  --region ${aws_region} \
  --template-url https://${S3_BUCKET_NAME}.s3.amazonaws.com/aws-cfn.yaml \
  --parameters ParameterKey=InstanceType,UsePreviousValue=true \
               ParameterKey=KeyName,UsePreviousValue=true \
  --capabilities CAPABILITY_NAMED_IAM

result=$(echo $?)
if [ "${result}" != "0" ]; then
  exit ${result}
fi

# Will wait for the stack to be provisioned successfully
echo 'Waiting for the stack to be updated, this may take a few minutes...'
aws cloudformation wait stack-update-complete --stack-name ${STACK_NAME}

result=$(echo $?)
exit ${result}
