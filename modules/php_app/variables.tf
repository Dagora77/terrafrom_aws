variable "cidr_block" {
  type        = string
  description = "valid subnets to assign to server"
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr_block" {
  type        = string
  description = "valid subnets to assign to server"
  default     = "10.0.10.0/24"
}

variable "public_subnet_b_cidr_block" {
  type        = string
  description = "valid subnets to assign to server"
  default     = "10.0.11.0/24"
}

variable "private_subnet_a_cidr_block" {
  type        = string
  description = "valid subnets to assign to server"
  default     = "10.0.20.0/24"
}

variable "private_subnet_b_cidr_block" {
  type        = string
  description = "valid subnets to assign to server"
  default     = "10.0.21.0/24"
}

variable "env" {
  type        = string
  description = "valid subnets to assign to server"
  default     = "prod"
}

variable "instance_type" {
  type        = string
  description = "valid subnets to assign to server"
  default     = "t2.micro"
}
/*
variable "env_security_group" {
  type        = string
  description = "valid subnets to assign to server"
}

variable "aws_db_php" {
  type        = string
  description = "valid subnets to assign to server"
}

variable "aws_db_php_endpoint" {
  type        = string
  description = "valid subnets to assign to server"
}

variable "region" {
  description = "Please enter AWS region to deploy server"
  default     = "us-east-2"
}
*/

variable "user" {
  type    = string
  default = "root"
}

variable "password" {
  type    = string
  default = "5526c03ba6"
}

variable "allow_ports" {
  description = "Enter ports to open"
  type        = list(any)
  default     = ["80", "443", "3306"]
}
