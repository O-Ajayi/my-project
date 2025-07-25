# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Subnet Information
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

# Network Load Balancer Information
output "nlb_id" {
  description = "ID of the Network Load Balancer"
  value       = aws_lb.main.id
}

output "nlb_arn" {
  description = "ARN of the Network Load Balancer"
  value       = aws_lb.main.arn
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.main.dns_name
}

output "nlb_zone_id" {
  description = "Canonical hosted zone ID of the Network Load Balancer"
  value       = aws_lb.main.zone_id
}

output "nlb_internal" {
  description = "Whether the NLB is internal"
  value       = aws_lb.main.internal
}

# Target Group Information
output "target_group_id" {
  description = "ID of the target group"
  value       = aws_lb_target_group.main.id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.main.arn
}

output "target_group_name" {
  description = "Name of the target group"
  value       = aws_lb_target_group.main.name
}

# Listener Information
output "listener_arn" {
  description = "ARN of the NLB listener"
  value       = aws_lb_listener.main.arn
}

output "listener_port" {
  description = "Port of the NLB listener"
  value       = aws_lb_listener.main.port
}

output "listener_protocol" {
  description = "Protocol of the NLB listener"
  value       = aws_lb_listener.main.protocol
}

# Security Group Information
output "security_group_id" {
  description = "ID of the security group for target instances"
  value       = aws_security_group.nlb_targets.id
}

# Target Instance Information (if created)
output "target_instance_ids" {
  description = "IDs of the target instances"
  value       = var.create_target_instances ? aws_instance.targets[*].id : []
}

output "target_instance_private_ips" {
  description = "Private IP addresses of the target instances"
  value       = var.create_target_instances ? aws_instance.targets[*].private_ip : []
}

# NAT Gateway Information
output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IP addresses of the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# Connection Information
output "connection_info" {
  description = "Information for connecting to the NLB"
  value = {
    nlb_dns_name    = aws_lb.main.dns_name
    listener_port   = var.listener_port
    protocol        = var.protocol
    connection_url  = "${lower(var.protocol)}://${aws_lb.main.dns_name}:${var.listener_port}"
  }
}