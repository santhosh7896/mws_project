data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_iam_role" "cloudwatch_role" {
  name = "ec2-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_attach" {
  role       = aws_iam_role.cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "cloudwatch_profile" {
  name = "cloudwatch-profile"
  role = aws_iam_role.cloudwatch_role.name
}

resource "aws_instance" "mws_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.mws_subnet.id
  vpc_security_group_ids = [aws_security_group.mws_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.cloudwatch_profile.name
  associate_public_ip_address = false

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    throughput  = 135
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              yum install -y git
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              cd /home/ec2-user
              git clone https://github.com/YOUR-USERNAME/YOUR-REPO.git website
              docker run -d -p 8000:80 -v /home/ec2-user/website:/usr/share/nginx/html nginx
              yum install -y amazon-cloudwatch-agent
              cat <<EOC > /opt/aws/amazon-cloudwatch-agent/bin/config.json
              {
                "metrics": {
                  "append_dimensions": {
                    "InstanceId": "\${aws:InstanceId}"
                  },
                  "metrics_collected": {
                    "mem": {
                      "measurement": ["mem_used_percent"]
                    },
                    "disk": {
                      "measurement": ["used_percent"],
                      "resources": ["*"]
                    }
                  }
                }
              }
              EOC
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
              EOF

  tags = { Name = "mws-ec2" }
}