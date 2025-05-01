terraform {
  backend "s3" {
    bucket = "team-debug-tf-state" # Not managed as a tf resource. Make changes manually
    key    = "tfstate"
    region = "eu-west-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_ecr_repository" "team_debug_app_repo" {
  name                 = "team-debug-app-repo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_iam_instance_profile" "team_debug_ec2_instance_profile" {
  name = "team_debug-ec2-instance-profile"
  role = aws_iam_role.team_debug_ec2_role.name
}

resource "aws_iam_role" "team_debug_ec2_role" {
  name = "team-debug-ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

locals {
  policies = {
    ec2_full_access           = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
    eb_web_tier               = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
    eb_multi_container_docker = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
    eb_worker_tier            = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
    ecr_read_only             = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }
}

resource "aws_iam_role_policy_attachment" "team_debug_policies" {
  for_each   = local.policies
  role       = aws_iam_role.team_debug_ec2_role.name
  policy_arn = each.value
}

resource "aws_elastic_beanstalk_application" "team_debug_proxy_server" {
  name        = "team-debug-proxy-server"
  description = "Proxy server"
}

resource "aws_elastic_beanstalk_environment" "team_debug_proxy_environment" {
  name        = "team-debug-proxy-environment"
  application = aws_elastic_beanstalk_application.team_debug_proxy_server.name

  # This page lists the supported platforms
  # we can use for this argument:
  # https://docs.aws.amazon.com/elasticbeanstalk/latest/platforms/platforms-supported.html#platforms-supported.docker
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.1 running Docker"

  

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.team_debug_ec2_instance_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = "jackdench"
  }
}

resource "aws_s3_bucket" "container_bucket" {
  bucket = "team-debug-container-bucket"
  tags = {
    "name" = "team-debug-container-bucket"
  }
}