terraform {
  required_providers {
    aws= {
        source = "hashicorp/aws"
        version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.profile
  shared_credentials_file = "/home/sreeramvellanki/work/rootkey.csv"
}

resource "aws_vpc" "project_vpc" {
  cidr_block = var.custom_vpc

  tags = {
    Name = var.vpc_tags
  }
}

resource "aws_internet_gateway" "project_ig" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    Name = var.internet_gateway_tags
  }
}

resource "aws_subnet" "project_public_subnet" {
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = var.public_subnet
  availability_zone = var.aws_zone1
  map_public_ip_on_launch = true

  tags = {
    Name = var.public_subnet_tags
    "kubernetes.io/roles/elb" = "1"
    "kubernetes.io/cluster/demo" = "owned"
  }
}

resource "aws_subnet" "project_private_subnet" {
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = var.private_subnet1
  availability_zone = var.aws_zone1

  tags = {
    Name = var.private_subnet_tags1
    "kubernetes.io/roles/internal-elb" = "1"
    "kubernetes.io/cluster/demo" = "owned"
  }
}

resource "aws_subnet" "project_public_subnet2" {
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = var.public_subnet2
  availability_zone = var.aws_zone2
  map_public_ip_on_launch = true

  tags = {
    Name = var.public_subnet_tags2
    "kubernetes.io/roles/elb" = "1"
    "kubernetes.io/cluster/demo" = "owned"
  }
}

resource "aws_subnet" "project_private_subnet2" {
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = var.private_subnet2
  availability_zone = var.aws_zone2

  tags = {
    Name = var.private_subnet_tags2
    "kubernetes.io/roles/internal-elb" = "1"
    "kubernetes.io/cluster/demo" = "owned"
  }
}

resource "aws_eip" "nat"{
    vpc = true

    tags = {
        Name = "nat"
    }
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.project_public_subnet.id

    tags= {
        Name = "nat"
    }

    depends_on = [aws_internet_gateway.project_ig]
}

resource "aws_route_table" "private_rt"{
    vpc_id = aws_vpc.project_vpc.id

    route = [
        {
            cidr_block = "0.0.0.0/0"
            nat_gateway_id = aws_nat_gateway.nat.id
            carrier_gateway_id = ""
            destination_prefix_list_id = ""
            egress_only_gateway_id = ""
            gateway_id = ""
            instance_id = ""
            ipv6_cidr_block = ""
            local_gateway_id = ""
            network_interface_id = ""
            transit_gateway_id = ""
            vpc_endpoint_id = ""
            vpc_peering_connection_id = ""
            core_network_arn = ""
        },
    ]

    tags = {
        Name = "private"
    }
}

resource "aws_route_table" "public_rt"{
    vpc_id = aws_vpc.project_vpc.id

    route = [
        {
            cidr_block = "0.0.0.0/0"
            nat_gateway_id = aws_nat_gateway.nat.id
            carrier_gateway_id = ""
            destination_prefix_list_id = ""
            egress_only_gateway_id = ""
            gateway_id = ""
            instance_id = ""
            ipv6_cidr_block = ""
            local_gateway_id = ""
            network_interface_id = ""
            transit_gateway_id = ""
            vpc_endpoint_id = ""
            vpc_peering_connection_id = ""
            core_network_arn = ""
        },
    ]

    tags = {
        Name = "public"
    }
}

resource "aws_route_table_association" "public_1_rt_a" {
  subnet_id      = aws_subnet.project_public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_rt_a" {
  subnet_id      = aws_subnet.project_public_subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_1_rt_a" {
  subnet_id      = aws_subnet.project_private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2_rt_a" {
  subnet_id      = aws_subnet.project_private_subnet2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_iam_role" "demo"{
    name = "eks-cluster-demo"

    assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect" : "Allow",
            "Principal" : {
                "Service" : "eks.amazonaws.com"
            },
            "Action" : "sts:AssumeRole"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "demo-AmazonEKSClusterPolicy"{
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role = aws_iam_role.demo.name
}

resource "aws_eks_cluster" "demo" {
    name= "demo"
    role_arn = aws_iam_role.demo.arn

    vpc_config {
      subnet_ids = [
        aws_subnet.project_public_subnet.id,
        aws_subnet.project_private_subnet2.id,
        aws_subnet.project_public_subnet.id,
        aws_subnet.project_private_subnet2.id
      ]
    }
    depends_on = [aws_iam_role_policy_attachment.demo-AmazonEKSClusterPolicy]
}

resource "aws_iam_role" "nodes" {
  name = "eks-node-group-nodes"
  assume_role_policy = <<POLICY

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKSWorkerNodePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKS_CNI_Policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEC2ContainerRegistryReadOnly" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role = aws_iam_role.nodes.name
}

resource "aws_eks_node_group" "private-nodes" {
    cluster_name = aws_eks_cluster.demo.name
    node_group_name = "private-nodes"
    node_role_arn = aws_iam_role.nodes.arn

    subnet_ids = [
        aws_subnet.project_private_subnet.id,
        aws_subnet.project_private_subnet2.id
    ]

    capacity_type = "ON_DEMAND"
    instance_types = ["t3.small"]

    scaling_config {
      desired_size = 1
      max_size= 5
      min_size = 1
    }

    update_config {
        max_unavailable = 1
    }

    labels = {
        role = "general"
    }
    depends_on = [
        aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy,
        aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
        aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly
    ]
}

data "tls_certificate" "eks" {
    url = aws_eks_cluster.demo.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks"{
    client_id_list = ["sts.amazonaws.com"]
    thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
    url = aws_eks_cluster.demo.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "test_oidc_assume_role_policy"{
    statement {
        actions = ["sts:AssumeRoleWithWebIdentity"]
        effect = "Allow"

        condition{
            test = "StringEquals"
            variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://","")}:sub"
            values = ["system:serviceaccount:default:aws-test"]
        }

        principals {
            identifiers = [aws_iam_openid_connect_provider.eks.arn]
            type = "Federated"
        }
    }
}

resource "aws_iam_role" "test_oidc" {
    assume_role_policy = data.aws_iam_policy_document.test_oidc_assume_role_policy.json
    name = "test_oidc"
}

resource "aws_iam_policy" "test-policy"{
    name = "test_policy"

    policy = jsonencode({
        Statement = [{
            Action = [
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation"
            ]
            Effect = "Allow"
            Resource = "arn:aws:s3:::*"
        }]
        Version = "2012-10-17"
    })
}

resource "aws_iam_role_policy_attachment" "test_attach" {
    role = aws_iam_role.test_oidc.name
    policy_arn = aws_iam_policy.test-policy.arn
}

output "test_policy_arn"{
    value = aws_iam_role.test_oidc.arn
}