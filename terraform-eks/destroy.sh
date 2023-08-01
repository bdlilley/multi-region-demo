#!/bin/bash

clusters=("mgmt-1" "mgmt-2" "workload-1" "workload-2")
for c in ${clusters[@]}; do
   kubectl scale deployment argocd-server -n argocd --replicas=0 --context ${c}
   kubectl delete ilm -A --all --context ${c} --wait=false
   kubectl delete glm -A --all --context ${c} --wait=false
   kubectl delete iop -A --all --context ${c} --wait=false
   kubectl delete svc -A --all --context ${c} --wait=false
done

terraform init \
  -var-file ../terraform-values/$TF_VAR_FILE \
  -var-file ./common.tfvars \
  -backend-config=bucket=$TF_STATE_BUCKET \
  -backend-config=key=$TF_STATE_KEY \
  -backend-config=region=$TF_STATE_REGION

terraform destroy \
  -var-file ../terraform-values/$TF_VAR_FILE \
  -var-file ./common.tfvars
