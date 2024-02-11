resource "aws_security_group" "endpoint_sg" {
  count  = var.enable_ssh ? 1 : 0
  name   = "${var.vpc_id}-connect-endpoint-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = merge(var.tags, {
    Usage = "EC2"
  })
}
#
resource "aws_security_group" "this" {
  name   = "${var.vpc_id}-allow-ssh-sg"
  vpc_id = var.vpc_id
  dynamic "ingress" {
    for_each = var.enable_ssh ? [1] : []
    content {
      from_port       = 22
      to_port         = 22
      protocol        = "TCP"
      security_groups = [aws_security_group.endpoint_sg[0].id]
    }
  }
  dynamic "ingress" {
    for_each = var.ingresses
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = [data.aws_vpc.target.cidr_block]
    }
  }
  #  ingress {
  #    from_port       = 22
  #    to_port         = 22
  #    protocol        = "TCP"
  #    security_groups = [aws_security_group.endpoint_sg[0].id]
  #    #    cidr_blocks      = ["0.0.0.0/0"]
  #    #    ipv6_cidr_blocks = ["::/0"]
  #  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, {
    Usage = "EC2"
  })
}

resource "aws_ec2_instance_connect_endpoint" "this_endpoint" {
  count              = var.enable_ssh ? 1 : 0
  subnet_id          = data.aws_subnets.private_subnets.ids[0]
  preserve_client_ip = true
  security_group_ids = var.enable_ssh ? [aws_security_group.endpoint_sg[0].id] : []
  tags = merge(var.tags, {
    Usage = "EC2"
  })
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.ubuntu_22_04_amd64.image_id
  instance_type               = "t2.micro"
  count                       = var.instance_number
  subnet_id                   = data.aws_subnets.private_subnets.ids[0]
  associate_public_ip_address = false
  vpc_security_group_ids      = var.enable_ssh ? [aws_security_group.this.id] : []
  ebs_block_device {
    device_name           = "/dev/sdf"
    delete_on_termination = var.ebs_delete_on_termination
    volume_size           = var.ebs_volume_size
    volume_type           = var.ebs_volume_type
  }
  instance_initiated_shutdown_behavior = var.shutdown_behavior
  disable_api_termination              = var.termination_protection
  disable_api_stop                     = var.stop_protection
  user_data                            = var.user_data != "" ? file("${path.module}/ec2/${var.user_data}") : null
  tags = merge(var.tags, {
    Usage = "EC2"
  })
}