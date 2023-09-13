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

provider "google" {
  project = var.project_id
  region = "us-central1-b"
}

provider "google-beta" {
  config_path = pathexpand("~/.kube/config")
  project = var.project_id
  region = "us-central1-b"
}

data "google_compute_backend_service" "jupyter-ingress" {
#   name = "k8s-be-30733--41409e2a13d12590"
  project = var.project_id

  depends_on = [ kubectl_manifest.static_ingress, kubectl_manifest.managed_cert, kubectl_manifest.backend_config ]
}

resource "kubectl_manifest" "backend_config" {
  override_namespace = var.namespace
  yaml_body          = templatefile("${path.module}/../deployments/backend-config.yaml", {})
}

resource "kubectl_manifest" "managed_cert" {
  override_namespace = var.namespace
  yaml_body          = templatefile("${path.module}/../deployments/managed-cert.yaml", {
    ip_addr = "${var.reserved_ip}.nip.io"
  })
}

resource "kubectl_manifest" "static_ingress" {
  override_namespace = var.namespace
  yaml_body          = templatefile("${path.module}/../deployments/static-ingress.yaml", {
    static_addr_name = "${var.reserved_ip_name}"
  })
}

# create secret based on OAuth cleint input by user
resource "kubernetes_secret" "my-secret" {
  metadata {
    name = "my-secret"
    namespace = var.namespace
  }

  # Omitting type defaults to `Opaque` which is the equivalent of `generic` 
  data = {
    "client_id" = var.client_id
    "client_secret" = var.client_secret
  }
}