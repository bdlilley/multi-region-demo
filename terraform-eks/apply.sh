#!/bin/bash

terraform apply \
  -var-file ../terraform-values/$TF_VAR_FILE \
  -var-file ./common.tfvars 

terraform output -json > ../terraform-outputs/eks.json
