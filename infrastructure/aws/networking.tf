# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default Subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group to allow outgoing internet access (to download pip packages)
resource "aws_security_group" "ecs_sg" {
  name   = "${var.project_name}-sg"
  vpc_id = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}