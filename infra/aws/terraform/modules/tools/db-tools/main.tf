#data "aws_ami" "amazon_linux_ami" {
#  most_recent = true
#  owners = ["amazon"]
#
#  filter {
#    name   = "name"
#    values = ["ami-0551ce4d67096d606"]
#  }
#}

resource "aws_instance" "oracle" {
  ami           = "ami-0551ce4d67096d606"
  instance_type = "t3.medium"
  vpc_security_group_ids = [var.security_group_id]
  subnet_id = var.vpc_public_subnets[0]
  key_name = var.ssh_key_name
  associate_public_ip_address = true

  user_data = file("${path.module}/userdata/download_and_install_tools.sh")

  tags = {
    app = var.ssh_key_name
  }
}
