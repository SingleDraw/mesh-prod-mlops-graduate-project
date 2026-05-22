data "http" "myip" {
  url = "https://api.ipify.org"
}

locals {
  my_ip = "${chomp(data.http.myip.response_body)}/32"

  # Client Secret
  client_secret_name   = "${var.application_name}-client-secret"
}