
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

# --------------------------------
# Install ArgoCD using Helm
locals {
  # LoadBalancer = public access
  # ClusterIP = internal access (requires port-forwarding or ingress)
  argocd_service_type = "LoadBalancer"
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = var.argocd_namespace

  repository       = local.helm_repository
  chart            = var.chart_name
  version          = var.chart_version

  create_namespace = false

  # Option 1: LoadBalancer for public access:
  # set {
  #   name  = "server.service.type"
  #   value = "LoadBalancer"
  # }
  # set {
  #   # whitelist your IP for security 
  #   # (replace with your actual public IP or CIDR range)
  #   name  = "server.service.loadBalancerSourceRanges[0]"
  #   value = "YOUR.PUBLIC.IP/32"
  # }
  dynamic "set" {
    for_each = var.argocd_service_type == "LoadBalancer" ? [
      {
        name  = "server.service.type"
        value = "LoadBalancer"
      },
      {
        name  = "server.service.loadBalancerSourceRanges[0]"
        value = "YOUR.PUBLIC.IP/32"
      }
    ] : [
      {
        name  = "server.service.type"
        value = "ClusterIP"
      },
      {
        name = "server.ingress.enabled"
        value = "true"
      },
      {
        name = "server.ingress.ingressClassName"
        value = "nginx"
      },
      {
        # name = "server.ingress.hosts[0]"
        # value = "argocd.local"
        name = "server.ingress.hostname"
        value = "argocd.yourdomain.com"
      }
    ]
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  # disable default admin account
  set {
    name  = "configs.cm.admin.enabled"
    value = "false"
  }
  # set {
  #   name  = "configs.secret.argocdServerAdminPassword"
  #   value = var.argocd_admin_password
  # }

  # create new user 'dev' with login and API key capabilities
  set {
    name  = "configs.cm.accounts\\.dev"
    value = "login,apiKey"
  }

  set {
    name  = "configs.secret.extra.accounts\\.dev\\.password"
    value = var.argocd_admin_password_bcrypt  # pre-hashed value
  }
  
  depends_on = [kubernetes_namespace.argocd]
}

# # --------------------------------
# # wait for CRD (bootstrap safe dependency)
# resource "null_resource" "wait_for_argocd_crd" {
#   depends_on = [helm_release.argocd]

#   provisioner "local-exec" {
#     command = "kubectl wait --for=condition=established crd/applications.argoproj.io --timeout=180s"
#   }
# }

# --------------------------------
# FIX #4: replace fragile null_resource/local-exec with time_sleep
# helm_release already waits for chart readiness; this just adds a small buffer
# for CRD propagation before dependent resources are created
resource "time_sleep" "wait_for_argocd_crds" {
  depends_on      = [helm_release.argocd]
  create_duration = "30s"
}

# --------------------------------
# RBAC (custom restricted role)
# Username: dev, Password: set via var.argocd_admin_password_bcrypt (pre-hashed)
resource "kubernetes_cluster_role" "argocd_restricted" {
  metadata {
    name = "argocd-restricted"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps", "secrets", "serviceaccounts", "events", "endpoints", "namespaces"]
    verbs      = ["get", "list", "watch", "create", "update", "delete", "patch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets", "daemonsets"]
    verbs      = ["get", "list", "watch", "create", "update", "delete", "patch"]
  }


  # FIX #3: ArgoCD controller must be able to manage its own CRDs
  rule {
    api_groups = ["argoproj.io"]
    resources  = ["applications", "appprojects", "applicationsets"]
    verbs      = ["get", "list", "watch", "create", "update", "delete", "patch"]
  }

  # FIX #3: batch resources commonly deployed via ArgoCD
  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch", "create", "update", "delete", "patch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["get", "list", "watch", "create", "update", "delete", "patch"]
  }
}

# role binding
resource "kubernetes_cluster_role_binding" "argocd_controller_binding" {
  metadata {
    name = "argocd-controller-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.argocd_restricted.metadata[0].name
  }

  subject {
    # it's created by helm chart, so we just bind to existing sa
    kind      = "ServiceAccount"
    name      = "argocd-application-controller"
    namespace = var.argocd_namespace
  }

  depends_on = [
    # kubernetes_cluster_role.argocd_restricted, 
    # helm_release.argocd, 
    time_sleep.wait_for_argocd_crds
  ]
}






# # --------------------------------
# # ArgoCD Application manifest (moved to GitOps ArgoCD responsibility)
# resource "kubernetes_manifest" "my_app" {
#   manifest = {
#     apiVersion = "argoproj.io/v1alpha1"
#     kind       = "Application"
#     metadata = {
#       name      = var.app_name
#       namespace = var.argocd_namespace
#     }
#     spec = {
#       project = var.project
#       source = {
#         repoURL        = var.repository_url
#         targetRevision = var.target_revision                   # lub konkretny branch/tag/commit
#         path           = var.repository_path  # Ścieżka w repozytorium do katalogu z manifestami Kubernetes dla tej aplikacji
#       }
#       destination = {
#         server    = var.server # Cel to ten sam klaster, na którym jest ArgoCD
#         namespace = var.destination_namespace                # Namespace w klastrze, do którego będą wdrażane zasoby z tej aplikacji
#       }
#       syncPolicy = var.sync_policy # Opcjonalnie, możesz ustawić automatyczną synchronizację
#     }
#   }
#   # depends_on = [helm_release.argocd, null_resource.wait_for_argocd_crd]
#   depends_on = [null_resource.wait_for_argocd_crd]
# }


# # ---------------------------------
# # Secret for ArgoCD admin password (get password)

# # argocd login secret (helm chart created)
# data "kubernetes_secret" "argocd_admin" {
#   metadata {
#     name      = "argocd-initial-admin-secret"
#     namespace = var.argocd_namespace
#   }
#   depends_on = [helm_release.argocd]
# }

# # --------------------------------
# # Outputs
# output "argocd_admin_password" {
#   value       = base64decode(data.kubernetes_secret.argocd_admin.data.password)
#   description = "Initial admin password for ArgoCD (decoded from Kubernetes secret)"
#   sensitive   = true
# }

