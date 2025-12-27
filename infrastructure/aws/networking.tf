resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "az1" {
  availability_zone = "${var.aws_region}a"
}
resource "aws_default_subnet" "az2" {
  availability_zone = "${var.aws_region}b"
}

resource "aws_security_group" "ecs_sg" {
  name   = "${var.project_name}-ecs-sg"
  vpc_id = aws_default_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# This ensures you only use the subnets you explicitly defined in code
data "aws_subnets" "default" {
  filter {
    name   = "subnet-id"
    values = [aws_default_subnet.az1.id, aws_default_subnet.az2.id]
  }
}