resource "aws_iam_role" "cloudwatch_role" {
  name = "ec2-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
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
  ami                         = "ami-03f4878755434977f" # Amazon Linux 2 x86_64 (gp2) for ap-south-1
  instance_type               = "t3.nano"
  subnet_id                   = aws_subnet.mws_subnet.id
  availability_zone           = "ap-south-1b"
  associate_public_ip_address = false
  security_groups             = [aws_security_group.mws_sg.id]
  key_name                    = "Projectkeypair"

  iam_instance_profile        = aws_iam_instance_profile.cloudwatch_profile.name

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    throughput  = 125
  }

  tags = {
    Name = "mws-ec2"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y git docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              cd /home/ec2-user
              git clone ${var.repo_url}
              cd mws_project

              docker run -d -p 8000:80 -v $(pwd)/index.html:/usr/share/nginx/html/index.html nginx

              yum install -y amazon-cloudwatch-agent

              cat <<EOC > /opt/aws/amazon-cloudwatch-agent/bin/config.json
              {
                "metrics": {
                  "append_dimensions": {
                    "InstanceId": "$${aws:InstanceId}"
                  },
                  "metrics_collected": {
                    "mem": {
                      "measurement": [
                        "mem_used_percent"
                      ],
                      "metrics_collection_interval": 60
                    }
                  }
                }
              }
              EOC

              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -a fetch-config \
                -m ec2 \
                -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
                -s
            EOF
}
