############ AWS General  ########################

variable "name" {
  description = "The name to append to the resources created by this module"
  type        = string
}

variable "region" {
  description = "The AWS region to use"
  type        = string
  default     = "eu-west-1"
}

variable "tags" {
  description = "A map of tags to attach to the resources created by this module"
  type        = map(any)
  default     = {}
}

variable "contact" {
  description = "A contact email to include on in all resource tags"
  type        = string
}


############ AWS EKS #############################

variable "eks_kubernetes_version" {
  description = "the version of kubernetes to use for the global CP cluster"
  type        = string
  default     = "1.22"
}

variable "eks_instance_size" {
  description = "the instance size to use for the global cp node group"
  type        = string
  default     = "t3.xlarge"
}

variable "eks_min_size" {
  description = "the minimal number of nodes in the global cp node group"
  type        = number
  default     = 1
}

variable "eks_max_size" {
  description = "the maximum number of nodes in the global cp node group"
  type        = number
  default     = 1
}

variable "eks_desired_size" {
  description = "the desired number of nodes in the global cp node group"
  type        = number
  default     = 1
}

variable "cluster_1_create" {
  description = "Should we create the zone a cluster"
  type        = bool
  default     = true
}

variable "zone_id" {
  description = "The zone ID of the route 53 zone we need to use"
  type        = string
}
