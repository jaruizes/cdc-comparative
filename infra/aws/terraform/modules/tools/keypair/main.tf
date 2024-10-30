resource "aws_key_pair" "tools_keypair" {
  key_name   = var.keypair_name
  public_key = file("${path.module}/../../../../ssh/toolskey.pub")

  tags = {
    app = var.keypair_name
  }
}
