resource "aws_eks_cluster" "self_managed_cluster" {
  name     = "selfeks"
  role_arn = aws_iam_role.self_managed_cluster_role.arn  //in below steps this role is created 
  

  vpc_config {
    security_group_ids      = [aws_security_group.self-managed-eks-cluster-sg.id] //this is created in below steps 
    // it is the sg of eks cluster
    endpoint_private_access = true
    endpoint_public_access  = false
    subnet_ids              = [aws_subnet.self-managed-public-subnet.id, aws_subnet.self-managed-private-subnet.id]
 //select all the subnets in the vpc, so eks can create eni in all subnets
 // so nodes in this subnet can communicate with eks control plane
  }


  depends_on = [
    aws_iam_role_policy_attachment.self-managed-eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.self-managed-eks-AmazonEKSServicePolicy
  ]


}





# creating cluster role

resource "aws_iam_role" "self_managed_cluster_role" {
  name = "self_managed_cluster_role"
assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

tags= {
  Name= "self_managed_cluster_role"
}

}



# creating and attching policies to cluster

resource "aws_iam_role_policy_attachment"     "self-managed-eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy" // default
  role       = aws_iam_role.self_managed_cluster_role.name   // adding this policy to above role called "self_managed_cluster_role"

 


}
resource "aws_iam_role_policy_attachment" "self-managed-eks-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy" //default
  role       = aws_iam_role.self_managed_cluster_role.name   //  adding this policy to above role called "self_managed_cluster_role"

  

}


# EKS Control Plane security group

resource "aws_security_group" "self-managed-eks-cluster-sg" {
  name        = "self-managed-eks-cluster-sg"
  description = "Communication between the control plane and worker nodegroups"
  vpc_id      = aws_vpc.self_managed_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] //all out going 
  }
    ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = ["${aws_eip.ec2-jump-eip.public_ip}/32"]
  }
tags = {
  Name ="self-managed-eks-cluster-sg"
}

}



// create single ingress or egress rule which can be attached to any sg

resource "aws_security_group_rule" "self_managed_cluster_inbound_rule" {
  # cidr_blocks = [local.myterraform-ip]  // public ip of terraform machine
  # cidr_blocks = ["0.0.0.0/0"]
  
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_eks_cluster.self_managed_cluster.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.self-managed-nodes-sg.id
  to_port           = 0
  type              = "ingress"
  # depends_on = [aws_eks_cluster.self_managed_cluster]
  

}
