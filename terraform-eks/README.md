# Installation

**Requirements**

* working AWS cli (can you `aws sts get-caller-identity`?)
* Terraform cli

**Deploy AWS Resources**

1. Review / edit [../terraform-values/common.tfvars](../terraform-values/common.tfvars).  You only need to modify this file if you want to use different regions or network configurations.
2. Review / edit [../terraform-values/my-demo.tfvars](../terraform-values/my-demo.tfvars).
3. Review / edit Kustomize patches in [../argocd/_install_argocd/](../argocd/_install_argocd/); you can opt-out of Okta RBAC but must keep the IAM for pods configuration to allow ArgoCD to manage remote clusters.
4. Deploy resources
```bash
cd terraform-eks

# Set these to your own values for terraform state in S3
#; (optional) or change [./_providers.tf](./_providers.tf) to not use S3 for state
export TF_VAR_FILE="my-demo.tfvars"
export TF_STATE_BUCKET=YOUR-BUCKET-NAME
export TF_STATE_KEY=ha-demo
export TF_STATE_REGION=us-east-1
# set this to change redis auth secret
TF_VAR_redis_auth=s0l0-123!

./init.sh

./plan.sh

./apply.sh
```
1. Set up local contexts (use this context naming if you want to copy/paste the rest of the steps!).  **Terraform output contains these commands you can copy/paste**:
```
  aws eks update-kubeconfig --name ha-demo-mgmt-1 --region us-east-1
  kubectl config rename-context arn:aws:eks:us-east-1:931713665590:cluster/ha-demo-mgmt-1 mgmt-1
  aws eks update-kubeconfig --name ha-demo-mgmt-2 --region us-east-2
  kubectl config rename-context arn:aws:eks:us-east-2:931713665590:cluster/ha-demo-mgmt-2 mgmt-2
  aws eks update-kubeconfig --name ha-demo-workload-1 --region us-east-1
  kubectl config rename-context arn:aws:eks:us-east-1:931713665590:cluster/ha-demo-workload-1 workload-1
  aws eks update-kubeconfig --name ha-demo-workload-2 --region us-east-2
  kubectl config rename-context arn:aws:eks:us-east-2:931713665590:cluster/ha-demo-workload-2 workload-2
```
  
**Register All Clusters w/ ArgoCD**

```bash
# patch aws-auth to allow argocd remote management
clusters=("mgmt-2" "workload-1" "workload-2")
for c in ${clusters[@]}; do
  # I would not use system:masters in production; instead remove groups and create role bindings for username argocd
  ROLE="    - rolearn: `terraform output --json | jq -r --arg cluster "$c" '.iam_argocd.value[$cluster]'`\n      username: argocd\n      groups:\n        - system:masters"
  kubectl get -n kube-system configmap/aws-auth --context ${c} -o yaml | awk "/mapRoles: \|/{print;print \"$ROLE\";next}1" > /tmp/aws-auth-patch.yml
  kubectl patch configmap/aws-auth -n kube-system --context ${c} --patch "$(cat /tmp/aws-auth-patch.yml)"
done

# install argocd and mgmt-1 and register all other clusters
kubectl create namespace argocd --context mgmt-1
kubectl apply -k ../argocd/_install_argocd --context mgmt-1

# configure the remote clusters in mgmt-1
clusters=("mgmt-2" "workload-1" "workload-2")
for c in ${clusters[@]}; do 
  kubectl apply --context mgmt-1 -f - <<EOT
apiVersion: v1
kind: Secret
metadata:
  name: ${c}
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: ${c}
  server: `terraform output --json | jq -r --arg cluster "$c" '.eks.value[$cluster].eks.endpoint'`
  config: |
    {
      "awsAuthConfig": {
        "clusterName": "`terraform output --json | jq -r --arg cluster "$c" '.eks.value[$cluster].eks.name'`",
        "roleARN": "`terraform output --json | jq -r --arg cluster "$c" '.iam_argocd.value[$cluster]'`"
      },
      "tlsClientConfig": {
        "insecure": false,
        "caData": "`terraform output --json | jq -r --arg cluster "$c" '.eks.value[$cluster].eks.certificate_authority[0].data'`"
      }
    }
EOT
done
```

**Secrets**

```bash
clusters=("mgmt-1" "mgmt-2" "workload-1" "workload-2")
for c in ${clusters[@]}; do
  kubectl create ns gloo-mesh  --context ${c} 
done

# redis auth and gloo license secrets
kubectl create secret generic redis-config --context mgmt-1 \
  --namespace gloo-mesh \
  --from-literal=token="${TF_VAR_redis_auth}" \
  --from-literal=host="`terraform output --json | jq -r '."redis-primary-us-east-1".value.host'`"

kubectl create secret generic redis-config --context mgmt-2 \
  --namespace gloo-mesh \
  --from-literal=token="${TF_VAR_redis_auth}" \
  --from-literal=host="`terraform output --json | jq -r '."redis-secondary-us-east-2".value.host'`"

# gloo license secrets
kubectl create secret generic license --context mgmt-1 \
  --namespace gloo-mesh \
  --from-literal=gloo-trial-license-key=${LICENSE_KEY}

kubectl create secret generic license --context mgmt-2 \
  --namespace gloo-mesh \
  --from-literal=gloo-trial-license-key=${LICENSE_KEY}
```

**Deploy Apps w/ ArgoCD**

***optional - change static app values***

The [../argocd/_argocd-apps/](../argocd/_argocd-apps/) folder contains several static app definitions that refer to this repo (`repoURL: https://github.com/bensolo-io/multi-region-demo.git`).

You may wish to change some of these values.  For example, [../argocd/_argocd-apps/gloo-platform-mgmt-1.yaml](../argocd/_argocd-apps/gloo-platform-mgmt-1.yaml) contains the Gloo Platform deployment for `v2.4.0`.  To use your own values:

1. Fork this repo and make the changes you desire
2. Find and replace `repoURL: https://github.com/bensolo-io/multi-region-demo.git` with your own repo URL.  

**create apps**

```bash
kubectl apply -f ../argocd/_argocd-apps/ --context mgmt-1
```

# Cleanup

```bash
./destroy.sh
```