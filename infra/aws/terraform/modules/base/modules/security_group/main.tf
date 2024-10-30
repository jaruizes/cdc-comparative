resource "aws_security_group" "general_security_group" {
  name_prefix = "${var.sg_name}_general_security_group"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port = 1521
    to_port   = 1521
    protocol  = "tcp"
    description = "Oracle RDS"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    app = var.sg_name
  }
}
