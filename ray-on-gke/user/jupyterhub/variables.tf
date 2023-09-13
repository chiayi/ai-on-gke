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

variable "namespace" {
  type        = string
  description = "Kubernetes namespace where resources are deployed"
  default     = "<your user name>"
}

variable "create_namespace" {
  type = bool
  description = "Enable creation of jupyterhub namespace if it does not exist"
  default = false
}

variable "client_id" {
  type = string
  description = "Client ID of the OAuth Client"
  default = "<Client ID Here>"
  sensitive = true
}

variable "client_secret" {
  type = string
  description = "Client secret of the OAuth Client"
  default = "<Client secret here>"
  sensitive = true
}

variable "project_id" {
  type        = string
  description = "GCP project id"
  default     = "<your project>"
}

variable "project_number" {
  type        = string
  description = "GCP project number"
  default     = "<your project number>"
}