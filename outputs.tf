output "lb_endpoint" {
  value = "http://${aws_lb.my_alb.dns_name}/docs"
}