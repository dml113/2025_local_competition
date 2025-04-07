################################################################################################################################################
#                                                                 EC2                                                                          #
################################################################################################################################################

# aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-2023*" "Name=architecture,Values=x86_64" --query "Images[? !contains(Name, 'minimal')] | sort_by(@, &CreationDate) | [-1].ImageId" --output text

module "ec2" {
  source = "./modules/EC2"
  bastion_name           = "bastion"
  ami_id                 = "ami-0a463f27534bdf246"
  instance_type          = "t3.small"
  subnet_id              = module.vpc.subnet_ids["public-subnet-a"]
  key_pair_name          = "bastion-key"
  iam_role_name          = "bastion-role"
  vpc_id                 = module.vpc.vpc_id
  user_data              = filebase64("${path.module}/user_data/user_data.sh")
}