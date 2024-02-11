resource "aws_security_group" "this" {
  count  = length(var.security_groups) == 0 ? 1 : 0
  name   = "${var.lb_name}-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 8000
    to_port          = 8999
    protocol         = "TCP"
    cidr_blocks      = [data.aws_vpc.target.cidr_block]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = merge(var.tags, {
    Usage = "ELB"
  })
}

resource "aws_lb" "this" {
  name                             = var.lb_name
  internal                         = var.internal
  load_balancer_type               = var.lb_type
  security_groups                  = length(var.security_groups) == 0 ? [aws_security_group.this[0].id] : var.security_groups
  subnets                          = length(var.subnets) == 0 ? data.aws_subnets.public_subnets.ids : var.subnets
  enable_cross_zone_load_balancing = var.cross_zone_load_balancing

  dynamic "access_logs" {
    for_each = var.access_logs.enabled ? [1] : []
    content {
      enabled = true
      bucket  = var.access_logs.bucket_id
      prefix  = var.access_logs.prefix
    }
  }

  tags = merge(var.tags, {
    Usage = "ELB"
    Name  = "${var.vpc_id}-${var.lb_name}"
  })
}

resource "aws_lb_listener" "default" {
  count             = length(var.listeners)
  load_balancer_arn = aws_lb.this.arn
  port              = var.listeners[count.index].port
  protocol          = var.listeners[count.index].protocol

  default_action {
    type             = var.listeners[count.index].action_type
    target_group_arn = aws_alb_target_group.default.arn
  }
  depends_on = [aws_alb_target_group.default]
  tags = merge(var.tags, {
    Usage = "ELB"
  })
}

resource "aws_alb_target_group" "default" {
  name        = "${aws_lb.this.name}-target-group"
  port        = var.target_group.port
  protocol    = var.target_group.protocol
  vpc_id      = var.vpc_id
  target_type = var.target_group.target_type
  tags = merge(var.tags, {
    Usage = "ELB"
  })
}

resource "aws_lb_target_group_attachment" "default" {
  for_each         = toset(data.aws_instances.lb_targets.ids)
  target_group_arn = aws_alb_target_group.default.arn
  target_id        = each.value
  port             = var.target_group.port
}