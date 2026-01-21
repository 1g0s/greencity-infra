#
# GreenCity AWS Infrastructure - Input Variables
#

# General
variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "greencity"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-1"
}

# VPC
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.1.10.0/24", "10.1.20.0/24"]
}

# EKS
variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
  default     = ["t3.large"]  # Java backends need 8GB RAM
}

variable "eks_node_desired_size" {
  description = "Desired number of nodes in EKS node group"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of nodes in EKS node group"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of nodes in EKS node group"
  type        = number
  default     = 4
}

variable "eks_node_disk_size" {
  description = "Disk size in GB for EKS nodes"
  type        = number
  default     = 50
}

# RDS
variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "rds_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Maximum allocated storage for RDS autoscaling in GB"
  type        = number
  default     = 100
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.15"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS (increases cost)"
  type        = bool
  default     = false  # Cost optimization
}

variable "rds_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 7
}

variable "rds_database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "greencity"
}

variable "rds_username" {
  description = "Master username for RDS"
  type        = string
  default     = "greencity"
}

# Application Configuration (sensitive)
variable "email_address" {
  description = "Email address for SMTP"
  type        = string
  sensitive   = true
  default     = ""
}

variable "email_password" {
  description = "Email password for SMTP"
  type        = string
  sensitive   = true
  default     = ""
}

variable "google_client_id" {
  description = "Google OAuth client ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "google_api_key" {
  description = "Google API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "azure_connection_string" {
  description = "Azure Storage connection string"
  type        = string
  sensitive   = true
  default     = ""
}

variable "azure_container_name" {
  description = "Azure Storage container name"
  type        = string
  default     = "greencity"
}

# ECR
variable "ecr_image_retention_count" {
  description = "Number of images to retain in ECR"
  type        = number
  default     = 10
}

# CloudWatch
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
