
# outputy do sprawdzenia statusu aplikacji
output "argocd_app_name" {
  value = kubernetes_manifest.my_app.manifest.metadata.name
}
# # Ten output może być przydatny do debugowania, ale często status aplikacji sprawdza się bezpośrednio w panelu ArgoCD lub przez CLI
# # Zasób kubernetes_manifest w Terraformie często ma problem z czytaniem pól status 
# # zaraz po utworzeniu (bo pole to wypełnia kontroler Argo CD wewnątrz klastra, 
# # a nie sam Terraform). Może to powodować błędy przy pierwszym terraform apply.
# output "argocd_app_status" {
#   value = kubernetes_manifest.my_app.status
# }