resource "aws_efs_file_system" "this" {
  availability_zone_name          = var.availability_zone
  encrypted                       = var.encrypted
  kms_key_id                      = var.kms_key_id
  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.provisioned_throughput_in_mibps
  lifecycle_policy {
    transition_to_ia = var.lifecycle_policy.transition_to_ia
    #    transition_to_primary_storage_class = var.lifecycle_policy.transition_to_primary_storage_class
    #    transition_to_archive               = var.lifecycle_policy.transition_to_archive
  }
  tags = merge(var.tags, {
    Usage = "EFS"
    Name = var.name
  })
  lifecycle {
    precondition {
      condition     = !var.encrypted || var.encrypted && var.kms_key_id != "" && var.kms_key_id != null
      error_message = "Kms key must be specified when encryption is enabled"
    }
    precondition {
      condition     = var.throughput_mode != "provisioned" || var.throughput_mode == "provisioned" && var.provisioned_throughput_in_mibps > 0
      error_message = "Provisioned throughput must be specified when throughput mode is provisioned"
    }
  }
}

resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id
  backup_policy {
    status = var.backup ? "ENABLED" : "DISABLED"
  }
}

resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id
  posix_user {
    gid            = var.user.gid
    uid            = var.user.uid
    secondary_gids = var.user.secondary_gids
  }
  root_directory {
    path = var.root_directory
    creation_info {
      owner_gid   = var.owner.owner_gid
      owner_uid   = var.owner.owner_uid
      permissions = var.owner.permissions
    }
  }
}

resource "aws_security_group" "access_in_vpc" {
  name   = "efs-${aws_efs_file_system.this.id}-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port        = 2049
    to_port          = 2049
    protocol         = "TCP"
    cidr_blocks      = [data.aws_vpc.target.cidr_block]
  }
  tags = merge(var.tags, {
    Usage = "EFS"
  })
}

resource "aws_efs_mount_target" "targets" {
  count           = length(data.aws_subnets.private_subnets.ids)
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = data.aws_subnets.private_subnets.ids[count.index]
  security_groups = [aws_security_group.access_in_vpc.id]
}