resource "aws_vpc" "mws_vpc" {
  cidr_block                     = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true
  tags = { Name = "mws-vpc" }
}

resource "aws_subnet" "mws_subnet" {
  vpc_id                          = aws_vpc.mws_vpc.id
  cidr_block                      = "10.0.1.0/24"
  availability_zone               = "ap-south-1a"
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.mws_vpc.ipv6_cidr_block, 8, 0)
  assign_ipv6_address_on_creation = true
  tags = { Name = "mws-subnet" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mws_vpc.id
  tags = { Name = "mws-igw" }
}

resource "aws_eip" "eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.mws_subnet.id
  tags = { Name = "mws-nat" }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.mws_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }

  tags = { Name = "mws-rt" }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.mws_subnet.id
  route_table_id = aws_route_table.rt.id
}