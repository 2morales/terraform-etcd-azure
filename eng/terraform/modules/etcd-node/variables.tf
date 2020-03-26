variable "deployment_name" {
  type        = string
  description = "Deployment name."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
}

variable "location" {
  type        = string
  description = "Private network location."
}

variable "etcd_initial_cluster" {
  type        = string
  description = "Initial cluster nodes URLs."
}

variable "zone_name" {
  type        = string
  description = "DNS zone name."
}

variable "network_profile_id" {
  type        = string
  description = "Network profile ID."
}
