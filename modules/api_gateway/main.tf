terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

resource "yandex_api_gateway" "backend_gw" {
  name                = "project-backend-gw"
  description         = "API Gateway for serverless backend"

  spec = <<EOF
openapi: 3.0.0
info:
  title: Exchange API
  version: 1.0.0

paths:
  /{proxy+}:
    x-yc-apigateway-any-method:
      parameters:
        - name: proxy
          in: path
          required: true
          schema:
            type: string
      x-yc-apigateway-integration:
        type: serverless_containers
        container_id: ${var.backend_container_id}
        service_account_id: ${var.api_gw_service_account_id}
        timeout: 30s
        headers:
          Authorization: "{request.headers.Authorization}"
EOF
}
