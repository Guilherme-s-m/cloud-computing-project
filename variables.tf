variable "ami_id" {
    description = "AMI ID for the EC2 instance"
    default="ami-0fc5d935ebf8bc3bc"
    type=string
    }
variable "instance_type" {
    description = "Instance type for the EC2 instance"
    default="t2.micro"
    type=string
    }
variable "security_groups" {
    description = "List of security group IDs to associate with the EC2 instance"
    default=["sg-0d844f50c76ccd466"]
    type=list(string)
    }
variable "iam_instance_profile" {
    description = "IAM instance profile to associate with the EC2 instance"
    default="guilhermesm9"
    type=string
}
variable "subnet_id" {
    description = "Subnet ID to associate with the EC2 instance"
    default="subnet-018e16f0c7cdd4d35"
    type=string
}

variable "vpc_cidr" {
  description = "CIDR block for the entire VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_sub_1_cidr" {
  description = "CIDR block for the public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_sub_2_cidr" {
  description = "CIDR block for the public subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_sub_1_cidr" {
  description = "CIDR block for the private subnet 1"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_sub_2_cidr" {
  description = "CIDR block for the private subnet 2"
  type        = string
  default     = "10.0.4.0/24"
}

variable "availability_zone_1" {
  description = "Availability zone 1"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_2" {
  description = "Availability zone 2"
  type        = string
  default     = "us-east-1b"
}

variable "alb_sg_id" {
  description = "Security group ID for the ALB"
  type        = string
  default     = "sg-0d844f50c76ccd466"
}