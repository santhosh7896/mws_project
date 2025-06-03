resource "aws_security_group" "mws_sg" {
  name   = "mws-sg"
  vpc_id = aws_vpc.mws_vpc.id

  ingress {
    from_port         = 8000
    to_port           = 8000
    protocol          = "udp"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

  egress {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

  tags = { Name = "mws-sg" }
}