
provider "aws" {
  region  = var.aws_region
  version = "~> 2.40"
}

terraform {
  backend          "s3"             {}
  required_version = "~> 0.12.16"
}

locals {
    num_azs = length(var.azs)

    azs = [
        for az in var.azs: format("%s%s", var.aws_region, az)
    ]

    bits = local.num_azs > 3 ? 4 : 2

    public_subnets  = [
        for i in range(local.num_azs) : "${cidrsubnet(
            cidrsubnet(var.cidr, local.bits, local.num_azs),
            local.bits, i
        )}"
    ]
    private_subnets = [
        for i in range(local.num_azs) : "${cidrsubnet(var.cidr, local.bits, i)}"
    ]
}

module "aws_vpc" {
    source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc?ref=tags/v2.21.0"

    name = var.name

    cidr = var.cidr
    
    azs             = local.azs
    public_subnets  = local.public_subnets
    private_subnets = local.private_subnets

    enable_dns_hostnames = true
    enable_dns_support   = true

    enable_nat_gateway = true

    enable_s3_endpoint       = true
    enable_dynamodb_endpoint = true
}
