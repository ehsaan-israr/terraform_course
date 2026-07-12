#!/usr/bin/env bash
set -euo pipefail

# LocalStack has no Amazon Linux catalog. Register a named image so Terraform
# can resolve an AMI with data.aws_ami.
awslocal ec2 register-image \
  --name "al2023-ami-localstack" \
  --description "Placeholder AMI for Terraform Module 1 LocalStack labs" \
  --architecture x86_64 \
  --root-device-name /dev/sda1 \
  --virtualization-type hvm \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":8,"DeleteOnTermination":true,"VolumeType":"gp2"}}]' \
  >/tmp/register-ami.json

echo "Registered LocalStack AMI:"
cat /tmp/register-ami.json
