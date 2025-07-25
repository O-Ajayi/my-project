# AWS Network Load Balancer with Terraform

This Terraform configuration creates an AWS Network Load Balancer (NLB) with an internal scheme, along with all necessary supporting infrastructure including VPC, subnets, target groups, and optional target instances.

## Architecture

The configuration creates:

- **VPC** with DNS support enabled
- **Public and Private Subnets** across multiple Availability Zones
- **Internet Gateway** and **NAT Gateways** for outbound connectivity
- **Route Tables** and associations for proper traffic routing
- **Network Load Balancer** with internal scheme
- **Target Group** with configurable health checks
- **Security Groups** for target instances
- **Optional EC2 instances** as targets with a sample web application

## Features

- ✅ **Internal Network Load Balancer** - Only accessible from within the VPC
- ✅ **Multi-AZ Deployment** - High availability across multiple zones
- ✅ **Configurable Protocols** - Supports TCP, UDP, TCP_UDP, TLS, and HTTP
- ✅ **Health Checks** - Configurable health check parameters
- ✅ **Target Types** - Supports instance, IP, Lambda, and ALB targets
- ✅ **Cross-Zone Load Balancing** - Optional for even traffic distribution
- ✅ **Example Target Instances** - Optional EC2 instances with sample application

## Prerequisites

1. **Terraform** >= 1.0
2. **AWS CLI** configured with appropriate credentials
3. **AWS Provider** >= 5.0

## Quick Start

1. **Clone or download** this configuration
2. **Copy the example variables file**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
3. **Edit terraform.tfvars** with your desired configuration
4. **Initialize Terraform**:
   ```bash
   terraform init
   ```
5. **Plan the deployment**:
   ```bash
   terraform plan
   ```
6. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Configuration

### Basic Configuration

The most important variables to configure:

```hcl
# terraform.tfvars
aws_region   = "us-west-2"
project_name = "my-nlb"
environment  = "dev"

# Network settings
vpc_cidr     = "10.0.0.0/16"
subnet_count = 2

# Load balancer settings
target_port   = 80
listener_port = 80
protocol      = "TCP"
```

### Advanced Configuration

For production deployments, consider these settings:

```hcl
# Enhanced availability and security
subnet_count                     = 3
enable_deletion_protection       = true
enable_cross_zone_load_balancing = true

# Optimized health checks
health_check_interval            = 10
health_check_timeout             = 6
health_check_healthy_threshold   = 2
health_check_unhealthy_threshold = 2
```

## Use Cases

### 1. TCP Load Balancing (Default)
```hcl
protocol      = "TCP"
target_port   = 8080
listener_port = 80
```

### 2. HTTPS/TLS Termination
```hcl
protocol      = "TLS"
target_port   = 443
listener_port = 443
```

### 3. UDP Load Balancing
```hcl
protocol      = "UDP"
target_port   = 53
listener_port = 53
```

### 4. Container/IP Targets
```hcl
target_type             = "ip"
create_target_instances = false
```

## Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `aws_region` | AWS region to deploy resources | `string` | `"us-west-2"` |
| `project_name` | Name prefix for all resources | `string` | `"nlb-demo"` |
| `environment` | Environment name (dev/staging/prod) | `string` | `"dev"` |
| `vpc_cidr` | CIDR block for the VPC | `string` | `"10.0.0.0/16"` |
| `subnet_count` | Number of subnets (min 2 for HA) | `number` | `2` |
| `protocol` | Protocol (TCP/UDP/TCP_UDP/TLS/HTTP) | `string` | `"TCP"` |
| `target_port` | Port on target instances | `number` | `80` |
| `listener_port` | Port on load balancer | `number` | `80` |
| `target_type` | Target type (instance/ip/lambda/alb) | `string` | `"instance"` |
| `create_target_instances` | Create example EC2 instances | `bool` | `true` |

See `variables.tf` for the complete list of configurable options.

## Outputs

After deployment, you'll get important information including:

- **NLB DNS Name** - Use this to connect to your load balancer
- **Target Group ARN** - For registering additional targets
- **VPC and Subnet IDs** - For deploying additional resources
- **Security Group ID** - For target instance configuration

Example output:
```
nlb_dns_name = "nlb-demo-nlb-1234567890.elb.us-west-2.amazonaws.com"
target_group_arn = "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/nlb-demo-nlb-tg/50dc6c495c0c9188"
```

## Testing

If you created the example target instances (`create_target_instances = true`), you can test the load balancer:

1. **Get the NLB DNS name** from the Terraform outputs
2. **Connect from within the VPC** (since it's internal):
   ```bash
   curl http://internal-nlb-dns-name
   ```
3. **View the sample application** - Shows instance metadata and request counting

## Security Considerations

- The NLB is **internal only** - not accessible from the internet
- Target instances are in **private subnets**
- Security groups restrict access to the **target port only**
- NAT Gateways provide **outbound internet access** for updates

## Cost Optimization

- **Disable target instances** if you don't need them: `create_target_instances = false`
- **Reduce subnet count** for dev environments: `subnet_count = 2`
- **Use smaller instance types**: `instance_type = "t3.nano"`
- **Disable deletion protection** for non-production: `enable_deletion_protection = false`

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete all resources including the VPC, subnets, and load balancer.

## Troubleshooting

### Common Issues

1. **Target instances unhealthy**
   - Check security group allows traffic on target port
   - Verify application is running and responding on target port
   - Check health check configuration

2. **Cannot connect to NLB**
   - Ensure you're connecting from within the VPC (internal NLB)
   - Verify DNS name and port
   - Check route tables and security groups

3. **Terraform errors**
   - Ensure AWS credentials are configured
   - Check region availability for resources
   - Verify Terraform and provider versions

### Useful Commands

```bash
# Check NLB status
aws elbv2 describe-load-balancers --names nlb-demo-nlb

# Check target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# View Terraform state
terraform show

# Import existing resources
terraform import aws_lb.main <load-balancer-arn>
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

This configuration is provided as-is for educational and production use.
