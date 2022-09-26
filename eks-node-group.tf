resource "aws_key_pair" "self-managed-key-pair" {
  key_name   = "self-managed-key-pair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDL8h3XTJ1u+tNT39vawf8HgGkHGOnuc2g7TyjaQREoxLkVV4WpybJe0FW8rw37q6QjPh+uY9Q9NqdLKW+9QelIbASWqvT16j0Anp32G0h5KCPjXlxjibPG6t6JB97hjFid8VqAiJotAXg2689yBulupi93zXkS0OmiS/f5BIF9ZGq2J+PVWmovoeifSEuu32IItMV/YVP49ar3xW04q4gW1JT5EbmE860Gq1a3njCDesFQ5cgx9DFOYTbqB9EEhVbzztNwXUPvW16P66RTleUcen4y79dmTGr16wVjKztlUWx4goFAzp/GpydmZX/CAiEnQuSUVVcBVD8lUc6dKAApM+CYKpyBivgDIZFXpgPTzr2cxQ33SFIptmWi72AEfxxUGd4SjXl6KevKdgXWppNgdG4ZvS+kbcSg0Ss2JBhKkXaVFsCSClgt4WEsGuKRiPef3mE7mCAGnfpYdR1GaGLrhlXUcT754UomkVdf3KovqfW5t+IVBfX+h7rjlBqtqW0= root@ip-172-31-29-108"
}

/*
resource "aws_eks_node_group" "self-manged-node-group" {
  cluster_name    = aws_eks_cluster.self_managed_cluster.name
  node_group_name = "myprivate-node-group"
  node_role_arn   = aws_iam_role.self-manged-nodegroup-role.arn
  subnet_ids      = [aws_subnet.nated.id]
  scaling_config {
    desired_size = 1
    max_size     = 5
    min_size     = 1
  }
  

create_aws_auth_configmap = true
manage_aws_auth_configmap = true


launch_template {
  id      = aws_launch_template.eks_self_managed_nodes.id
  version = "$Latest"
}

  depends_on = [
    aws_iam_role_policy_attachment.self-managed-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.self-managed-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.self-managed-AmazonEC2ContainerRegistryReadOnly
  ]


}
*/
resource "aws_iam_role" "self-manged-nodegroup-role" {
  name = "self-manged-nodegroup-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
tags = {
  Name = "self-manged-nodegroup-role"
}

}

resource "aws_iam_role_policy_attachment" "self-managed-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.self-manged-nodegroup-role.name
}

resource "aws_iam_role_policy_attachment" "self-managed-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.self-manged-nodegroup-role.name
}

resource "aws_iam_role_policy_attachment" "self-managed-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.self-manged-nodegroup-role.name
}

resource "aws_iam_role_policy" "self-managed-node-group-ClusterAutoscalerPolicy" {
  name = "self-managed-node-group-ClusterAutoscalerPolicy"
  role = aws_iam_role.self-manged-nodegroup-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeAutoScalingInstances",
            "autoscaling:DescribeLaunchConfigurations",
            "autoscaling:DescribeTags",
            "autoscaling:SetDesiredCapacity",
            "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

}


resource "aws_security_group" "self-managed-nodes-sg" {
  name        = "self-managed-nodes-sg"
  description = "Communication between all nodes in the cluster"
  vpc_id      = aws_vpc.self_managed_vpc.id

  /* ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  } */
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_eip.ec2-jump-eip.public_ip}/32"]
  }
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_eks_cluster.self_managed_cluster.vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

 
}



resource "aws_iam_instance_profile" "self-managed-instance-profile" {
  name       = "self-managed-instance-profile"
  role       = aws_iam_role.self-manged-nodegroup-role.name
  tags = {
    Name = "self-managed-instance-profile"
  }
}


resource "aws_launch_template" "self_managed_node_template" {
  image_id             = data.aws_ami.selected_eks_optimized_ami.id
  instance_type        = "t3.small"
  key_name             = "self-managed-key-pair"
name = "self_managed_node_template"
  update_default_version = true
  vpc_security_group_ids = [aws_security_group.self-managed-nodes-sg.id]

  iam_instance_profile {
          arn = aws_iam_instance_profile.self-managed-instance-profile.arn
  }
  
  user_data = base64encode(templatefile("./user_data.sh", {
    cluster_name = "selfeks"
  
  }))


  lifecycle {
    create_before_destroy = true
  }
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
    }
  }
  tags = {
    Name = "self_managed_node_template"
  }
}


resource "aws_autoscaling_group" "self-managed-autoscaling-group" {
  name                 = "myautogroup"


  vpc_zone_identifier  = [aws_subnet.self-managed-private-subnet.id]
  max_size             = 3
  min_size             = 1
  desired_capacity     = 1

  launch_template { 
   id = aws_launch_template.self_managed_node_template.id
   version = "$Latest"
     }

dynamic "tag" {
  for_each = {
        "Name"                           = "selfeks-myautogroup-Node"
        "kubernetes.io/cluster/selfeks" = "owned"
        "k8s.io/cluster/selfeks"        = "owned"
  }
  
  content {
    key                 = tag.key
    value               = tag.value
    propagate_at_launch = true
  }
}


    depends_on = [
    aws_iam_role_policy_attachment.self-managed-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.self-managed-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.self-managed-AmazonEC2ContainerRegistryReadOnly
  ]
  
}



