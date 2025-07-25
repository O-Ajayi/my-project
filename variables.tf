# AWS Region
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

# Project Configuration
variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "nlb-demo"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_count" {
  description = "Number of subnets to create (should be at least 2 for high availability)"
  type        = number
  default     = 2
  validation {
    condition     = var.subnet_count >= 2
    error_message = "At least 2 subnets are required for high availability."
  }
}

# Load Balancer Configuration
variable "enable_deletion_protection" {
  description = "Enable deletion protection for the load balancer"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

# Target Group Configuration
variable "target_port" {
  description = "Port on which targets receive traffic"
  type        = number
  default     = 80
}

variable "listener_port" {
  description = "Port on which the load balancer listens"
  type        = number
  default     = 80
}

variable "protocol" {
  description = "Protocol for the target group (TCP, UDP, TCP_UDP, TLS, or HTTP)"
  type        = string
  default     = "TCP"
  validation {
    condition     = contains(["TCP", "UDP", "TCP_UDP", "TLS", "HTTP"], var.protocol)
    error_message = "Protocol must be one of: TCP, UDP, TCP_UDP, TLS, HTTP."
  }
}

variable "target_type" {
  description = "Type of target (instance, ip, lambda, or alb)"
  type        = string
  default     = "instance"
  validation {
    condition     = contains(["instance", "ip", "lambda", "alb"], var.target_type)
    error_message = "Target type must be one of: instance, ip, lambda, alb."
  }
}

# Health Check Configuration
variable "health_check_healthy_threshold" {
  description = "Number of consecutive health checks before considering target healthy"
  type        = number
  default     = 3
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive health check failures before considering target unhealthy"
  type        = number
  default     = 3
}

variable "health_check_interval" {
  description = "Approximate amount of time between health checks (seconds)"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Amount of time to wait for health check response (seconds)"
  type        = number
  default     = 10
}

variable "health_check_path" {
  description = "Health check path (only for HTTP/HTTPS protocols)"
  type        = string
  default     = "/"
}

# Target Instance Configuration (Optional)
variable "create_target_instances" {
  description = "Whether to create example EC2 instances as targets"
  type        = bool
  default     = true
}

variable "target_instance_count" {
  description = "Number of target instances to create"
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "EC2 instance type for target instances"
  type        = string
  default     = "t3.micro"
}