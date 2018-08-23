#!/usr/bin/env bash

aws cloudformation --region eu-west-1 create-stack --template-body https://s3.amazonaws.com/downloads.mesosphere.io/dcos-enterprise/stable/1.11.4/cloudformation/ee.single-master.cloudformation.json --stack-name tomislav-dcos-11-ee --tags Key=iit-billing-tag,Value=qa --capabilities CAPABILITY_NAMED_IAM --parameters file://aws-cli-params.json
