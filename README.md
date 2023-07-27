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

### Configure ArgoCD Multi-Cluster

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
kubectl apply -k argocd/ha-demo/_install_argocd --context mgmt-1

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

### Create Required Secrets

```bash
kubectl create ns gloo-mesh  --context mgmt-1 
kubectl create ns gloo-mesh  --context mgmt-2
kubectl create ns gloo-mesh  --context workload-1 
kubectl create ns gloo-mesh  --context workload-2

# redis auth secrets for mgmt servers
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

### Create apps in argo
```bash
kubectl apply -f argocd/ha-demo/_argocd-apps/ --context mgmt-1
```


<!-- 


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
    name: in-cluster
  project: default
  source:
    directory:
      jsonnet: {}
      recurse: true
    path: argocd/ha-demo/mgmt-1
    repoURL: https://github.com/bensolo-io/multi-region-demo.git
  syncPolicy:
    automated:
      prune: true
      selfHeal: true 
EOT

kubectl apply --context mgmt-1 -f -<<EOT
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cluster-common
  namespace: argocd
spec:
  destination:
    namespace: argocd
    name: in-cluster
  project: default
  source:
    directory:
      jsonnet: {}
      recurse: true
    path: argocd/ha-demo/_mgmt-common
    repoURL: https://github.com/bensolo-io/multi-region-demo.git
  syncPolicy:
    automated:
      prune: true
      selfHeal: true 
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
    name: in-cluster
  project: default
  source:
    directory:
      jsonnet: {}
      recurse: true
    path: argocd/ha-demo/mgmt-2
    repoURL: https://github.com/bensolo-io/multi-region-demo.git
  syncPolicy:
    automated:
      prune: true
      selfHeal: true 
EOT

kubectl apply --context mgmt-2 -f -<<EOT
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cluster-common
  namespace: argocd
spec:
  destination:
    namespace: argocd
    name: in-cluster
  project: default
  source:
    directory:
      jsonnet: {}
      recurse: true
    path: argocd/ha-demo/_mgmt-common
    repoURL: https://github.com/bensolo-io/multi-region-demo.git
  syncPolicy:
    automated:
      prune: true
      selfHeal: true 
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
    name: in-cluster
  project: default
  source:
    directory:
      jsonnet: {}
      recurse: true
    path: argocd/ha-demo/workload-1
    repoURL: https://github.com/bensolo-io/multi-region-demo.git
  syncPolicy:
    automated:
      prune: true
      selfHeal: true 
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
    name: in-cluster
  project: default
  source:
    directory:
      jsonnet: {}
      recurse: true
    path: argocd/ha-demo/workload-2
    repoURL: https://github.com/bensolo-io/multi-region-demo.git
  syncPolicy: 
    automated:
      prune: true
      selfHeal: true 
EOT


```

 -->
