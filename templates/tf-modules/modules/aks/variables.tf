variable "name" {
    type        = string
    description = "Nazwa klastra AKS (3-63 znaki, lowercase, cyfry i myślniki, musi zaczynać się literą)"
    default     = "mini-aks-test"
}

variable "resource_group_name" {
  type        = string
  description = "Nazwa Resource Group"
}

variable "location" {
  type        = string
  description = "Lokalizacja zasobu"
}

variable "dns_prefix" {
    type        = string
    description = "Unikalny prefix DNS dla klastra AKS (np. 'myakscluster'). Będzie używany do wygenerowania domeny dla API servera (np. myakscluster-12345.hcp.eastus.azmk8s.io)."
    default     = "aks-violent-vince"
}