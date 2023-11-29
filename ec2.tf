//load balancer
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  depends_on         = [aws_internet_gateway.my_igw]
  enable_deletion_protection = false

  tags = {
    Name = "my-alb"
  }
}
//target group
resource "aws_lb_target_group" "my_tg" {
  name     = "my-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name = "my-tg"
  }
}
//listener
resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.my_tg.arn
    type             = "forward"
  }
}
//launch template
resource "aws_launch_template" "my_lt" {
  name                   = "meu-launch-template"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  network_interfaces {
    security_groups = [aws_security_group.ec2_sg.id]
    associate_public_ip_address = true  # This associates a public IP with the instance
    subnet_id = aws_subnet.public_subnet_1.id
  }
  user_data = base64encode(<<-EOF
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y python3-pip python3-venv git

# Criação do ambiente virtual e ativação
python3 -m venv /home/ubuntu/myappenv
source /home/ubuntu/myappenv/bin/activate

# Clonagem do repositório da aplicação
git clone https://github.com/ArthurCisotto/aplicacao_projeto_cloud.git /home/ubuntu/myapp

# Instalação das dependências da aplicação
pip install -r /home/ubuntu/myapp/requirements.txt

sudo apt-get install -y uvicorn

# Configuração da variável de ambiente para o banco de dados
export DATABASE_URL="mysql+pymysql://dbadmin:password@${aws_db_instance.db_instance_1.endpoint}/db_instance_1"

cd /home/ubuntu/myapp
# Inicialização da aplicação
uvicorn main:app --host 0.0.0.0 --port 80 
    EOF
)
}

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier  = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  max_size             = 5
  min_size             = 2
  desired_capacity     = 2
  health_check_type    = "EC2"
  launch_template {
    id      = aws_launch_template.my_lt.id
    version = "$Latest"
  }
  target_group_arns    = [aws_lb_target_group.my_tg.arn]

  tag {
    key                 = "Name"
    value               = "ASG-Instance-guilherme"
    propagate_at_launch = true
  }
}
//cloudwatch alarm
resource "aws_cloudwatch_metric_alarm" "scale_up_on_cpu" {
  alarm_name          = "scale_up_on_cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}
//autoscaling up policy
resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale_up_policy"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 30
  autoscaling_group_name = aws_autoscaling_group.asg.name


}
//scale down alarm
resource "aws_cloudwatch_metric_alarm" "scale_down_on_cpu" {
  alarm_name          = "scale_down_on_cpu"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}
//autoscaling down policy
resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scale_down_policy"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 30
  autoscaling_group_name = aws_autoscaling_group.asg.name

}
//scale up down tracking
resource "aws_autoscaling_policy" "scale_up_down_tracking" {
  policy_type            = "TargetTrackingScaling"
  name                   = "scale-up-down-tracking"
  estimated_instance_warmup = 180
  autoscaling_group_name = aws_autoscaling_group.asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label = "${split("/", aws_lb.my_alb.id)[1]}/${split("/", aws_lb.my_alb.id)[2]}/${split("/", aws_lb.my_alb.id)[3]}/targetgroup/${split("/", aws_lb_target_group.my_tg.arn)[1]}/${split("/", aws_lb_target_group.my_tg.arn)[2]}"
    }
    target_value = 200
  }

  lifecycle {
    create_before_destroy = true 
  }
}
resource "aws_cloudwatch_log_group" "my_log_group" {
  name = "/my-fastapi-app/logs"
}