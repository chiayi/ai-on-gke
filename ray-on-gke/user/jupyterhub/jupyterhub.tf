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

data "kubectl_file_documents" "auth-reqs" {
  pattern = "${path.module}/deployments/*.yaml"
}

resource "helm_release" "jupyterhub" {
  name       = "jupyterhub"
  repository = "https://jupyterhub.github.io/helm-chart"
  chart      = "jupyterhub"
  namespace  = var.namespace
  create_namespace = var.create_namespace
  cleanup_on_fail = "true"

  values = [
    file("${path.module}/jupyter_config/config-selfauth.yaml")
  ]
}

# three resources here, possibly 4: managed cert, static ingress, backend config, and maybe secret
# below will attempt to create deployments in /deployments/
resource "kubectl_manifest" "managed-cert" {
  for_each = data.kubectl_file_documents.auth-reqs.manifests
  yaml_body = each.value
}

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
# Reserve IP Address
resource "google_compute_address" "default" {
  name   = "my-test-static-ip-address"
  region = "us-central1"
}

