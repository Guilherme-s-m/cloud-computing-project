resource "aws_db_instance" "db_instance_1" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  db_name              = "db_instance_1"
  username             = "dbadmin"
  password             = "password"
  parameter_group_name = "default.mysql8.0"

  skip_final_snapshot  = true
  vpc_security_group_ids = ["${aws_security_group.rds_sg.id}"]
  publicly_accessible = false
  db_subnet_group_name    = aws_db_subnet_group.my_db_subnet_group.name
  final_snapshot_identifier = "final-rds-snapshot-${formatdate("YYYYMMDDHHmmss", timestamp())}"
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Sun:04:30-Sun:05:30"
  multi_az                = true
    tags = {
        Name = "My DB Instance"
    }
}
resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "My DB Subnet Group"
  }
}