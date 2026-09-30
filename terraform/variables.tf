variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name prefix applied to all resources"
  type        = string
  default     = "cicd-python-app"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "public_key" {
  description = "SSH public key content used to create the EC2 key pair"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH into the instance (restrict this in real use)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_port" {
  description = "Public port on which the application is exposed"
  type        = number
  default     = 80
}
