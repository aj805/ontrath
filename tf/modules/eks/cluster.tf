module "eks" {
    source  = "terraform-aws-modules/eks/aws"
    version = "~> 20.0"
  
    cluster_name    = var.cluster_name
    cluster_version = "1.29"
    subnet_ids      = aws_subnet.private[*].id
    vpc_id          = aws_vpc.main.id
  
    cluster_endpoint_public_access = true

    enable_cluster_creator_admin_permissions = true

    enable_irsa = true

    # EKS Auto Mode
    # Should install the ALB Controller
    cluster_compute_config = {
        enabled    = true
        node_pools = ["general-purpose"]
    }

    tags = {
        "Environment" = "ajontra-dev"
    }
}

resource "aws_iam_role" "epoch_api" {
  name = "${var.cluster_name}-epoch-api"

  assume_role_policy = data.aws_iam_policy_document.ecr_assume_role.json
}

data "aws_iam_policy_document" "ecr_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:default:epoch-api"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecr_pull_attach" {
  role       = aws_iam_role.epoch_api.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
