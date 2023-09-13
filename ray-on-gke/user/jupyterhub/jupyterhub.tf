# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

provider "kubectl" {
  config_path = pathexpand("~/.kube/config")
}

provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}

provider "google" {
  project = var.project_id
  region = "us-central1-b"
}

# data "kubectl_path_documents" "auth-reqs" {
#   pattern = "${path.module}/deployments/*.yaml"
#   vars = {
#     # ip_addr = module.ingress.ingress.address
#     ip_addr = "${google_compute_global_address.default.address}.nip.io"
#     static_addr_name = google_compute_global_address.default.name
#   }

#   depends_on = [ google_compute_global_address.default, kubernetes_namespace.namespace ]
# }

# data "kubectl_path_documents" "auth-reqs-hack" {
#   pattern = "${path.module}/deployments/*.yaml"
#   vars = {
#     ip_addr = ""
#     static_addr_name = ""
#   }
# }

# data "google_compute_backend_service" "jupyter-ingress" {
#   name = "jupyter-ingress"
#   project = var.project_id

#   depends_on = [ kubectl_manifest.static_ingress ]
# }

resource "kubernetes_namespace" "namespace" {
  count = var.create_namespace ? 1 : 0
  metadata {
    labels = {
      namespace = var.namespace
    }

    name = var.namespace
  }
}

# data "local_file" "backend_config_yaml" {
#   filename = "${path.module}/deployments/backend-config.yaml"
# }

# data "local_file" "managed_cert_yaml" {
#   filename = "${path.module}/deployments/managed-cert.yaml"
# }

# data "local_file" "static_ingress_yaml" {
#   filename = "${path.module}/deployments/static-ingress.yaml"
# }

# resource "kubectl_manifest" "backend_config" {
#   override_namespace = var.namespace
#   yaml_body          = templatefile("${path.module}/deployments/backend-config.yaml", {})
#   depends_on = [ kubectl_manifest.static_ingress ]
# }

# resource "kubectl_manifest" "managed_cert" {
#   override_namespace = var.namespace
#   yaml_body          = templatefile("${path.module}/deployments/managed-cert.yaml", {
#     ip_addr = "${google_compute_global_address.default.address}.nip.io"
#   })
#   depends_on = [ kubectl_manifest.static_ingress ]
# }

# resource "kubectl_manifest" "static_ingress" {
#   override_namespace = var.namespace
#   yaml_body          = templatefile("${path.module}/deployments/static-ingress.yaml", {
#     static_addr_name = "${google_compute_global_address.default.name}"
#   })
#   depends_on = [ google_compute_global_address.default ]
# }

# Reserve IP Address
resource "google_compute_global_address" "default" {
  project      = var.project_id 
  name         = "jupyter-address"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}


module "ingress" {
  source = "./ingress_module"

  project_id = var.project_id
  namespace = var.namespace
  client_id = var.client_id
  client_secret = var.client_secret
  reserved_ip = google_compute_global_address.default.address
  reserved_ip_name = google_compute_global_address.default.name
}

resource "helm_release" "jupyterhub" {
  name       = "jupyterhub"
  repository = "https://jupyterhub.github.io/helm-chart"
  chart      = "jupyterhub"
  namespace  = var.namespace
  cleanup_on_fail = "true"

  values = [
    # file("${path.module}/jupyter_config/config-selfauth.yaml")
    templatefile("${path.module}/jupyter_config/config-selfauth.yaml", {
      # service_id = "${data.kubernetes_ingress_v1.jupyter-ingress.id}"
      # service_id = "${data.google_compute_backend_service.jupyter-ingress.name}"
      service_id = "${module.ingress.service_id}"
      # service_id = "8055507163035350380"
      project_number = "${var.project_number}"
    })
  ]

  depends_on = [ 
    module.ingress
    # data.kubernetes_ingress_v1.jupyter-ingress, 
    # data.google_compute_backend_service.jupyter-ingress,
  ]
}

# create secret based on OAuth cleint input by user
# resource "kubernetes_secret" "my-secret" {
#   metadata {
#     name = "my-secret"
#     namespace = var.namespace
#   }

#   # Omitting type defaults to `Opaque` which is the equivalent of `generic` 
#   data = {
#     "client_id" = var.client_id
#     "client_secret" = var.client_secret
#   }
# }

# three resources here, possibly 4: managed cert, static ingress, backend config, and maybe secret
# below will attempt to create deployments in /deployments/
# resource "kubectl_manifest" "deployment-reqs" {
#   count = length(data.kubectl_path_documents.auth-reqs-hack.documents)
#   yaml_body = element(data.kubectl_path_documents.auth-reqs.documents, count.index)

#   depends_on = [ kubernetes_secret.my-secret ]
# }

# Reserve IP Address
# resource "google_compute_global_address" "default" {
#   project      = var.project_id 
#   name         = "jupyter-address"
#   address_type = "EXTERNAL"
#   ip_version   = "IPV4"
# }
