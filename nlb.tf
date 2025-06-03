resource "aws_lb" "nlb" {
  name               = "mws-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.mws_subnet.id]
}

resource "aws_lb_target_group" "nlb_target" {
  name        = "mws-target-group"
  port        = 8000
  protocol    = "UDP"
  target_type = "instance"
  vpc_id      = aws_vpc.mws_vpc.id
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 8000
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_target.arn
  }
}

resource "aws_lb_target_group_attachment" "nlb_attachment" {
  target_group_arn = aws_lb_target_group.nlb_target.arn
  target_id        = aws_instance.mws_ec2.id
  port             = 8000
}