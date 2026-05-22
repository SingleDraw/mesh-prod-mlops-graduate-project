# ArgoCD terraform module
    This module defines a basic ArgoCD installation on an existing Kubernetes cluster. It uses the Helm provider to deploy ArgoCD from the official Helm chart.

```terraform
# 1. Tworzysz klaster przez moduł (lub bezpośrednio)
module "my_aks" {
  source = "./modules/aks_with_argo"
  # ... parametry modułu ...
}

# 2. KONFIGURUJESZ providera Helm danymi z modułu
provider "helm" {
  kubernetes {
    host                   = module.my_aks.aks_host
    client_certificate     = base64decode(module.my_aks.aks_client_certificate)
    client_key             = base64decode(module.my_aks.aks_client_key)
    cluster_ca_certificate = base64decode(module.my_aks.aks_cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = module.my_aks.aks_host
  client_certificate     = base64decode(module.my_aks.aks_client_certificate)
  client_key             = base64decode(module.my_aks.aks_client_key)
  cluster_ca_certificate = base64decode(module.my_aks.aks_cluster_ca_certificate)
}

# 3. Teraz możesz używać helm_release w module

```



USE APPLICATION MANIFEST IN REPO:

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/your/repo.git
    targetRevision: HEAD
    path: apps/my-app

  destination:
    server: https://kubernetes.default.svc
    namespace: my-app-ns

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true