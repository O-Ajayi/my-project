# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# Internet Gateway (for NAT Gateway if needed)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

# Private Subnets for NLB
resource "aws_subnet" "private" {
  count = var.subnet_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Private"
  }
}

# Public Subnets (for NAT Gateway)
resource "aws_subnet" "public" {
  count = var.subnet_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Public"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.subnet_count

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name        = "${var.project_name}-nat-eip-${count.index + 1}"
    Environment = var.environment
  }
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.subnet_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "${var.project_name}-nat-gateway-${count.index + 1}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  }
}

# Route Tables for Private Subnets
resource "aws_route_table" "private" {
  count = var.subnet_count

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name        = "${var.project_name}-private-rt-${count.index + 1}"
    Environment = var.environment
  }
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "public" {
  count = var.subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations for Private Subnets
resource "aws_route_table_association" "private" {
  count = var.subnet_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security Group for NLB (though NLB doesn't use security groups, this is for targets)
resource "aws_security_group" "nlb_targets" {
  name_prefix = "${var.project_name}-nlb-targets-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = var.target_port
    to_port     = var.target_port
    protocol    = var.protocol
    cidr_blocks = var.internal_nlb ? [var.vpc_cidr] : ["0.0.0.0/0"]
    description = var.internal_nlb ? "Allow traffic from VPC" : "Allow traffic from internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-nlb-targets-sg"
    Environment = var.environment
  }
}

# Target Group for Network Load Balancer
resource "aws_lb_target_group" "main" {
  name     = "${var.project_name}-nlb-tg"
  port     = var.target_port
  protocol = upper(var.protocol)
  vpc_id   = aws_vpc.main.id

  target_type = var.target_type

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    matcher             = var.protocol == "HTTP" ? "200" : null
    path                = var.protocol == "HTTP" ? var.health_check_path : null
    port                = "traffic-port"
    protocol            = upper(var.protocol)
    timeout             = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  tags = {
    Name        = "${var.project_name}-nlb-target-group"
    Environment = var.environment
  }
}

# Network Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-nlb"
  internal           = var.internal_nlb
  load_balancer_type = "network"
  subnets            = var.internal_nlb ? aws_subnet.private[*].id : aws_subnet.public[*].id

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  tags = {
    Name        = "${var.project_name}-nlb"
    Environment = var.environment
  }
}

# NLB Listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.listener_port
  protocol          = upper(var.protocol)

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = {
    Name        = "${var.project_name}-nlb-listener"
    Environment = var.environment
  }
}

# Example EC2 instances as targets (optional)
resource "aws_instance" "targets" {
  count = var.create_target_instances ? var.target_instance_count : 0

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[count.index % var.subnet_count].id
  vpc_security_group_ids = [aws_security_group.nlb_targets.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    port = var.target_port
  }))

  tags = {
    Name        = "${var.project_name}-target-instance-${count.index + 1}"
    Environment = var.environment
  }
}

# Data source for Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "main" {
  count = var.create_target_instances ? var.target_instance_count : 0

  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.targets[count.index].id
  port             = var.target_port
}