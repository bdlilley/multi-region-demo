#!/bin/bash

terraform plan \
  -var-file ../terraform-values/$TF_VAR_FILE \
  -var-file ./common.tfvars \
  -out plan.tfplan

# terraform output -json > ../dist/eks.json
