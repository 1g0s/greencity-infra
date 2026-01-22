#
# GreenCity AWS Infrastructure - Outputs
# Export important values for use in deployment scripts
#

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

# EKS Outputs
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_ca_certificate" {
  description = "EKS cluster CA certificate (base64)"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "eks_cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = aws_eks_cluster.main.version
}

output "eks_node_group_name" {
  description = "EKS node group name"
  value       = aws_eks_node_group.main.node_group_name
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.aws_region}"
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "RDS hostname"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.postgres.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.postgres.db_name
}

output "rds_username" {
  description = "RDS master username"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

output "rds_jdbc_url" {
  description = "JDBC connection URL"
  value       = "jdbc:postgresql://${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"
}

# ECR Outputs
output "ecr_backcore_url" {
  description = "ECR repository URL for BackCore"
  value       = aws_ecr_repository.backcore.repository_url
}

output "ecr_backuser_url" {
  description = "ECR repository URL for BackUser"
  value       = aws_ecr_repository.backuser.repository_url
}

output "ecr_frontend_url" {
  description = "ECR repository URL for Frontend"
  value       = aws_ecr_repository.frontend.repository_url
}

output "ecr_registry" {
  description = "ECR registry URL"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "ecr_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

# Secrets Manager Outputs
output "db_credentials_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "app_secrets_secret_arn" {
  description = "ARN of the application secrets secret"
  value       = aws_secretsmanager_secret.app_secrets.arn
}

# IAM Outputs
output "alb_controller_role_arn" {
  description = "IAM role ARN for ALB controller"
  value       = aws_iam_role.alb_controller.arn
}

# CloudWatch Outputs
output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}-dashboard"
}

# Summary
output "summary" {
  description = "Deployment summary"
  value = <<-EOT

    ╔════════════════════════════════════════════════════════════════╗
    ║           GreenCity AWS Infrastructure Deployed                ║
    ╠════════════════════════════════════════════════════════════════╣
    ║ EKS Cluster: ${aws_eks_cluster.main.name}
    ║ Region:      ${var.aws_region}
    ║
    ║ Configure kubectl:
    ║   aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.aws_region}
    ║
    ║ ECR Login:
    ║   aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
    ║
    ║ ECR Repositories:
    ║   - ${aws_ecr_repository.backcore.repository_url}
    ║   - ${aws_ecr_repository.backuser.repository_url}
    ║   - ${aws_ecr_repository.frontend.repository_url}
    ║
    ║ RDS Endpoint: ${aws_db_instance.postgres.endpoint}
    ║
    ║ Next Steps:
    ║   1. Configure kubectl with the command above
    ║   2. Push images to ECR
    ║   3. Apply Kubernetes manifests: kubectl apply -f k8s/
    ╚════════════════════════════════════════════════════════════════╝

  EOT
}
