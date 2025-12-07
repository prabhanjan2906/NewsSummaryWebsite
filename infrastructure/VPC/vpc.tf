variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  SubnetCount           = var.SubnetsCount
  cidr_sub_block_length = 8
  azs                   = data.aws_availability_zones.available.names
}

# 1. VPC
resource "aws_vpc" "news_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.env}-news-vpc"
  }

}

# 2. Internet Gateway for public subnets
resource "aws_internet_gateway" "news_igw" {
  vpc_id = aws_vpc.news_vpc.id

  tags = {
    Name = "${var.env}-news-igw"
  }

}

# 3. Public subnets (for NAT gateway, ALBs, etc.)
resource "aws_subnet" "public_subnets" {
  count                   = local.SubnetCount
  vpc_id                  = aws_vpc.news_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.news_vpc.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = local.azs[count.index]

  tags = {
    Name = "${var.env}-news-public-${count.index}"
  }

}

# resource "aws_subnet" "public_b" {
#   vpc_id                  = aws_vpc.news_vpc.id
#   cidr_block              = "10.0.2.0/24"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "news-public-b"
#   }

# }

# 4. Private subnets (for RDS + Lambdas)
resource "aws_subnet" "private_subnets" {
  count             = local.SubnetCount
  vpc_id            = aws_vpc.news_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.news_vpc.cidr_block, 8, local.SubnetCount + count.index)
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.env}-news-private-${count.index}"
  }
  lifecycle {
    prevent_destroy = true
  }
}

# resource "aws_subnet" "private_b" {
#   vpc_id     = aws_vpc.news_vpc.id
#   cidr_block = "10.0.12.0/24"

#   tags = {
#     Name = "news-private-b"
#   }

# }

# 5. Public route table (0.0.0.0/0 -> IGW)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.news_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.news_igw.id
  }

  tags = {
    Name = "${var.env}-news-public-rt"
  }

}

resource "aws_route_table_association" "public_subnet_assoc" {
  count          = local.SubnetCount
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# resource "aws_route_table_association" "public_b_assoc" {
#   subnet_id      = aws_subnet.public_b.id
#   route_table_id = aws_route_table.public_rt.id

# }

# 6. NAT Gateway in public subnet A
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.env}-news-nat-eip"
  }

}

resource "aws_nat_gateway" "news_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "${var.env}-news-nat"
  }

  depends_on = [aws_eip.nat_eip]
}

# 7. Private route table (0.0.0.0/0 -> NAT)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.news_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.news_nat.id
  }

  tags = {
    Name = "${var.env}-news-private-rt"
  }
  depends_on = [aws_internet_gateway.news_igw]
}

resource "aws_route_table_association" "private_subnet_assoc" {
  count          = local.SubnetCount
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# resource "aws_route_table_association" "private_b_assoc" {
#   subnet_id      = aws_subnet.private_b.id
#   route_table_id = aws_route_table.private_rt.id

# }

output "private_subnets_id" {
  value = aws_subnet.private_subnets[*].id
}

# output "private_subnet_b_id" {
#   value = aws_subnet.private_b.id
# }

output "public_subnets_id" {
  value = aws_subnet.public_subnets[*].id
}
