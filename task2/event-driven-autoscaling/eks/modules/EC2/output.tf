output "bastion_public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "Public IP of the Bastion host"
}

output "bastion_instance_id" {
  value       = aws_instance.bastion.id
  description = "Instance ID of the Bastion host"
}

output "bastion_key_file" {
  value       = var.key_file_path
  description = "Path to the private key file for the Bastion host"
}

output "bastion_role_arn" {
  value = aws_iam_role.bastion.arn
}

output "bastion_sg_id" {
  value = aws_security_group.Bastion_Instance_SG.id
}