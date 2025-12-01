variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "demo"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro" 
}

variable "key_name" {
  description = "SSH key pair name (debe existir en AWS)"
  type        = string
}

variable "salesforce_instance_url" {
  description = "Salesforce instance URL"
  type        = string
}

variable "salesforce_access_token" {
  description = "Salesforce access token"
  type        = string
  sensitive   = true
}
