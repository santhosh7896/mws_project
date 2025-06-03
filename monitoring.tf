resource "aws_sns_topic" "alarm_topic" {
  name = "mws-ec2-alarm-topic"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alarm_topic.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_metric_alarm" "ebs_usage_alarm" {
  alarm_name          = "EBS-Usage-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "VolumeConsumedReadWriteOps"
  namespace           = "AWS/EBS"
  period              = 300
  statistic           = "Sum"
  threshold           = 20
  alarm_actions       = [aws_sns_topic.alarm_topic.arn]

  dimensions = {
    VolumeId = aws_instance.mws_ec2.root_block_device[0].volume_id
  }
}
