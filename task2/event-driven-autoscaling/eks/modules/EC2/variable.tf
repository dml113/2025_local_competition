variable "vpc_id" {
  description = "vpc id"
  type        = string
}

variable "bastion_name" {
  description = "Name of the Bastion host"
  type        = string
  default     = "bastion"
}

variable "key_pair_name" {
  description = "Name of the Bastion key pair"
  type        = string  
}

variable "iam_role_name" {
  description = "Name of the Bastion role name"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the Bastion host"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the Bastion host"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the Bastion host will be launched"
  type        = string
}

variable "key_file_path" {
  description = "Local path to save the private key for SSH"
  type        = string
  default     = "~/.ssh/bastion_key.pem"
}

variable "user_data" {
  description = "EC2 User Data"
  type        = string
  default     = ""
}