terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ForgeAI-Integration"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Ubuntu 22.04 LTS
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


resource "aws_security_group" "forgeai" {
  name        = "forgeai-demo-sg"
  description = "Security group for ForgeAI demo"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Datos de demo, en producción restringir mas a ip especificas
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #opcional https 
  # ingress {
  #   description = "HTTPS"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags = {
    Name = "forgeai-demo-sg"
  }
}

# EC2 INSTANCE

resource "aws_instance" "forgeai" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.forgeai.id]
  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 8   # GB - suficiente para demo
    volume_type = "gp3"
  }

  # Script de inicialización
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    salesforce_instance_url = var.salesforce_instance_url
    salesforce_access_token = var.salesforce_access_token
  }))

  tags = {
    Name = "forgeai-demo"
  }
}

# ELASTIC IP (IP fija para no perderla al reiniciar)

resource "aws_eip" "forgeai" {
  instance = aws_instance.forgeai.id
  domain   = "vpc"

  tags = {
    Name = "forgeai-demo-eip"
  }
}
