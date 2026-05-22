# variable "name" {
#     type        = string
#     description = "Nazwa klastra AKS (3-63 znaki, lowercase, cyfry i myślniki, musi zaczynać się literą)"
#     default     = "mini-aks-test"
# }

# variable "resource_group_name" {
#   type        = string
#   description = "Nazwa Resource Group"
# }

variable "location" {
  type        = string
  description = "Lokalizacja zasobu"
}

variable "dns_prefix" {
    type        = string
    description = "Unikalny prefix DNS dla klastra AKS (np. 'myakscluster'). Będzie używany do wygenerowania domeny dla API servera (np. myakscluster-12345.hcp.eastus.azmk8s.io)."
    default     = "aks-violent-vince"
}

# ArgoCD variables
variable "app_name" {
    type        = string
    description = "Nazwa aplikacji ArgoCD, która będzie synchronizować się z repozytorium GitHub"
    default     = "moja-apka-testowa"
}

# variable "app_namespace" {
#     type        = string 
#     # ???
#     description = "App namespace - namespace w klastrze AKS, do którego będą wdrażane zasoby z aplikacji ArgoCD"
#     default     = "argocd"
# }

variable "chart_name" {
  type    = string
  default = "argo-cd"
}

variable "chart_version" {
  type    = string
  default = "5.51.6"
}

variable "repository_url" {
    type        = string
    description = "URL repozytorium GitHub dla aplikacji ArgoCD"
}

variable "repository_path" {
    type        = string
    description = "Ścieżka w repozytorium GitHub do katalogu z manifestami Kubernetes dla aplikacji ArgoCD"
    default     = "manifests/argocd-apps"
}

variable "target_revision" {
    type        = string
    description = "Branch/tag/commit w repozytorium GitHub, który ArgoCD będzie śledzić dla tej aplikacji"
    default     = "HEAD"
}

# variable "destination_namespace" {
#     type        = string
#     # ???
#     description = "Namespace w klastrze AKS, do którego będą wdrażane zasoby z aplikacji ArgoCD"
#     default     = "default"
# }

variable "server" {
    type        = string
    description = "URL API servera Kubernetes, do którego ArgoCD będzie się łączyć (zazwyczaj 'https://kubernetes.default.svc' dla połączenia wewnątrz klastra)"
    default     = "https://kubernetes.default.svc"
}

variable "sync_policy" {
    type        = any
    description = "Polityka synchronizacji dla aplikacji ArgoCD (np. automatyczna synchronizacja z opcjami prune i selfHeal)"
    default     = {
        automated = {
            prune    = true
            selfHeal = true
        }
    }
}


variable "argocd_namespace" {
  default = "argocd"
}

variable "destination_namespace" {
  default = "default"
}


variable "argocd_admin_password_bcrypt" {
  type      = string
  sensitive = true
}