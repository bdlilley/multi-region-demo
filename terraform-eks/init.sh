#!/bin/bash

terraform init \
  -var-file ../terraform-values/$TF_VAR_FILE \
  -var-file ./common.tfvars \
  -backend-config=bucket=$TF_STATE_BUCKET \
  -backend-config=key=$TF_STATE_KEY \
  -backend-config=region=$TF_STATE_REGION
