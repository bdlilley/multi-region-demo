# Requirements

* ArgoCD https://github.com/argoproj/argo-cd/releases
* 
  <!-- annotations:
    external-dns.alpha.kubernetes.io/hostname: nginx.example.com
     -->
     
export TF_VAR_FILE="ben-demo.tfvars"
export TF_STATE_BUCKET=solo-io-terraform-931713665590
export TF_STATE_KEY=ha-demo
export TF_STATE_REGION=us-east-2

cd terraform-eks
./apply.sh

commit and push up

# mgmt-1
kubectl create namespace argocd --context mgmt-1
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.0-rc3/manifests/install.yaml --context mgmt-1

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
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.0-rc3/manifests/install.yaml --context mgmt-2

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
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.0-rc3/manifests/install.yaml --context workload-1

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
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.0-rc3/manifests/install.yaml --context workload-2

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