# Requirements

* ArgoCD https://github.com/argoproj/argo-cd/releases
* 
  <!-- annotations:
    external-dns.alpha.kubernetes.io/hostname: nginx.example.com
     -->
    
# How TO

### Create AWS Resources

1. Create your own tfvars file (see `terraform-values/ben-demo.tfvars` as an example)
2. Determine terraform state storage and configure env vars (backend is set up for s3)
```bash
export TF_VAR_FILE="ben-demo.tfvars"
export TF_STATE_BUCKET=solo-io-terraform-931713665590
export TF_STATE_KEY=ha-demo
export TF_STATE_REGION=us-east-2
```
3. Apply terraform configurations - this could take 20+ minutes

This step writes some generated manifests into `argocd/<var.resourcePrefix>/` alongside the static manfifests (`var.resourcePrefix` comes from your tfvars file).

```bash
cd terraform-eks
./apply.sh
```

### Push Generated Files to Git

Commit and push files generated in the previous step.  In the next step you will point Argo to these to install.  From here you can choose to manually edit them and push up to git as-needed, or you can re-generated when appropriate.

### Set up kubeconfig

The terraform output containted the commands needed to add EKS clusters to a kubeconfig.  The remainder of steps assume you have renamed them to mgmt-1, mgmt-2, workload-1, workload-2.

### Install Argo and Apps

In this step you will apply some static manifests + generated manifests from prior steps to clusters for argo to manage.

1. Install argo 
```bash
# mgmt-1
kubectl create namespace argocd --context mgmt-1
kubectl apply -n argocd -f ./hack/argo-manifest.yaml --context mgmt-1

kubectl apply --context mgmt-1 -f -<<EOT
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cluster
  namespace: argocd
spec:
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
  project: default
  source:
    directory:
      jsonnet: {}
      recurse: true
    path: argocd/ha-demo/mgmt-1
    repoURL: https://github.com/bensolo-io/multi-region-demo.git
  syncPolicy:
    automated: {}
EOT

# mgmt-2
kubectl create namespace argocd --context mgmt-2
kubectl apply -n argocd -f ./hack/argo-manifest.yaml --context mgmt-2

kubectl apply --context mgmt-2 -f -<<EOT
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cluster
  namespace: argocd
spec:
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
  project: default
  source:
    directory:
      jsonnet: {}
      recurse: true
    path: argocd/ha-demo/mgmt-2
    repoURL: https://github.com/bensolo-io/multi-region-demo.git
  syncPolicy:
    automated: {}
EOT


# workload-1
kubectl create namespace argocd --context workload-1
kubectl apply -n argocd -f ./hack/argo-manifest.yaml --context workload-1

kubectl apply --context workload-1 -f -<<EOT
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cluster
  namespace: argocd
spec:
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
  project: default
  source:
    directory:
      jsonnet: {}
      recurse: true
    path: argocd/ha-demo/workload-1
    repoURL: https://github.com/bensolo-io/multi-region-demo.git
  syncPolicy:
    automated: {}
EOT

# workload-2
kubectl create namespace argocd --context workload-2
kubectl apply -n argocd -f ./hack/argo-manifest.yaml --context workload-2

kubectl apply --context workload-2 -f -<<EOT
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cluster
  namespace: argocd
spec:
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
  project: default
  source:
    directory:
      jsonnet: {}
      recurse: true
    path: argocd/ha-demo/workload-2
    repoURL: https://github.com/bensolo-io/multi-region-demo.git
  syncPolicy:
    automated: {}
EOT

# redis auth secrets for mgmt servers

kubectl create secret generic redis-config --context mgmt-1 \
  --namespace gloo-mesh \
  --from-literal=token="${TF_VAR_redis_auth}" \
  --from-literal=host="`terraform output --json | jq -r '."redis-primary-us-east-1".value.host'`"

kubectl create secret generic redis-config --context mgmt-2 \
  --namespace gloo-mesh \
  --from-literal=token="${TF_VAR_redis_auth}" \
  --from-literal=host="`terraform output --json | jq -r '."redis-secondary-us-east-2".value.host'`"
```