#!/bin/bash

rm -rf ../dist && mkdir -p ../dist

terraform init \
  -var-file ../terraform-values/$TF_VAR_FILE \
  -var-file ./common.tfvars \
  -backend-config=bucket=$TF_STATE_BUCKET \
  -backend-config=key=$TF_STATE_KEY \
  -backend-config=region=$TF_STATE_REGION

terraform apply \
  -var-file ../terraform-values/$TF_VAR_FILE \
  -var-file ./common.tfvars \
  --auto-approve

terraform output -json > ../dist/eks.json
