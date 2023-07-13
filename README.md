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

kubectl create namespace argocd --context mgmt-1
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.0-rc3/manifests/install.yaml  --context mgmt-1
kubectl config set-context --current --namespace=argocd
argocd login --core

argocd app create cluster \
  --repo https://github.com/bensolo-io/multi-region-demo.git \
  --path argocd/ha-demo/mgmt-1 \
  --dest-namespace argocd \
  --dest-server https://kubernetes.default.svc \
  --directory-recurse \
  --context mgmt-1