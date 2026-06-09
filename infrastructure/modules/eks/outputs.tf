# infrastructure/modules/eks/outputs.tf

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "node_group_role_arn" {
  value = module.eks.eks_managed_node_groups["main"].iam_role_arn
}

output "cloudwatch_irsa_role_arn" {
  value = module.cloudwatch_irsa.iam_role_arn
}

output "vpc_cni_irsa_role_arn" {
  value = module.vpc_cni_irsa.iam_role_arn
}

output "ebs_csi_irsa_role_arn" {
  value = module.ebs_csi_irsa.iam_role_arn
}
