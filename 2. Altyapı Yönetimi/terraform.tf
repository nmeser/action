# Cloud provider bilgileri ve Terraform version girilir.
provider "aws" {
  region  = "eu-central-1"
}
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.38.0"
    }
  }
}

# Vpc oluşturulur.Ekteki ss görüldüğü üzere Aws subnetlerde reserve ettiği IP ler bulunmaktadır.
# Bundan dolayı 62 kullanılabilir host ihtiyacı için "10.0.0.0/25" CIDR bloğu seçildi ve subnetler için yaklaşık 4 parçaya bölündü.
resource "aws_vpc" "main" { 
 cidr_block = "10.0.0.0/25"
 
}
# Public Subnet1
resource "aws_subnet" "pub_sub1" {  
vpc_id                  = aws_vpc.main.id  
cidr_block              = "10.0.0.0/27"  
availability_zone       = "eu-central-1a" 
map_public_ip_on_launch = true  
tags = {       
         Name = "public_subnet1"
      }
} # Public Subnet2 
resource "aws_subnet" "pub_sub2" {  
vpc_id                  = aws_vpc.main.id  
cidr_block              = "10.0.0.32/27" 
availability_zone       = "eu-central-1b" 
map_public_ip_on_launch = true  
tags = {    
         Name = "public_subnet2"  
       }
}

# Private Subnet1
resource "aws_subnet" "prv_sub1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.64/27"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "private_subnet1" 
 }
}# Private Subnet2
resource "aws_subnet" "prv_sub2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.96/27"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = false
  tags={
    Name = "private_subnet2"
  }
}

# Public subnetler için route table oluşturulur ve subnetlerle ilişkilendirilir.

# Public Route Table
resource "aws_route_table" "pub_sub1_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
   }
    tags = {
    Name = "public subnet route table" 
 }
}

# Route table association of public subnet1
resource "aws_route_table_association" "internet_for_pub_sub1" {
  route_table_id = aws_route_table.pub_sub1_rt.id
  subnet_id      = aws_subnet.pub_sub1.id
}# Route table association of public subnet2
resource "aws_route_table_association" "internet_for_pub_sub2" {
  route_table_id = aws_route_table.pub_sub1_rt.id
  subnet_id      = aws_subnet.pub_sub2.id
}

# Public subnetlerin internete çıkabilmesi için "Internet Gateway" oluşturulur.
# Internet Gateway 
resource "aws_internet_gateway" "igw" {  
   vpc_id = aws_vpc.main.id   
   tags = {      
            Name = "internet gateway"
          }
}



# ELB ve EC2'lar için Security Group tanımlanır.
# Security group for load balancer
resource "aws_security_group" "elb_sg" {
  name        = "load_balancer_sg"
  vpc_id      = aws_vpc.main.id
  ingress {

    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
 
 tags = {
    Name = "load_balancer_sg"
     
  } 
}
# Security group for webserver
resource "aws_security_group" "webserver_sg" {
  name        = "webserver_sg"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
   }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "webserver_sg" 
   
  }
}

# Auto Scaling Group için Launch config/template tanımlanır.
# Launch config
resource "aws_launch_configuration" "webserver-launch-config" {
  name_prefix   = "webserver-launch-config"
  image_id      =  "ami-05d34d340fb1d89e5"
  instance_type = "t2.micro"
  key_name = "hilos"
  security_groups = ["${aws_security_group.webserver_sg.id}"]
  
  root_block_device {
            volume_type = "gp2"
            volume_size = 10
            encrypted   = true
        }  
        ebs_block_device {
            device_name = "/dev/sdf"
            volume_type = "gp2"
            volume_size = 5
            encrypted   = true
        }
        lifecycle {
        create_before_destroy = true
     }
}

# Gerekli gördüğümüz EC2 sayısı için ASG tanımlanır.
# Auto Scaling Group
resource "aws_autoscaling_group" "Demo-ASG-tf" {
  name       = "Demo-ASG-tf"
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  force_delete       = true
  depends_on         = ["aws_lb.ALB-tf"]
  target_group_arns  =  ["${aws_lb_target_group.TG-tf.arn}"]
  health_check_type  = "EC2"
  launch_configuration = aws_launch_configuration.webserver-launch-config.name
  vpc_zone_identifier = ["${aws_subnet.prv_sub1.id}","${aws_subnet.prv_sub2.id}"]
  
 tag {
       key                 = "Name"
       value               = "Nezih-ASG-tf"
       propagate_at_launch = true
    }
}

# Create Target group
resource "aws_lb_target_group" "TG-tf" {
  name     = "Nezih-TargetGroup-tf"
  depends_on = ["aws_vpc.main"]
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"
  health_check {
    interval            = 70
    path                = "/index.html"
    port                = 80
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 60 
    protocol            = "HTTP"
    matcher             = "200,202"
  }
}

# Trafiği yönlendirmesi için ALB oluşturulur.
# ALB
resource "aws_lb" "ALB-tf" {
   name              = "Nezih-ALG-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups  = [aws_security_group.elb_sg.id]
  subnets          = [aws_subnet.pub_sub1.id,aws_subnet.pub_sub2.id]       
  tags = {
        name  = "Nezih-AppLoadBalancer-tf"
       }
}
# ALB'nin dinleyeceği portlar Listener'a eklenir.
# ALB Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.ALB-tf.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TG-tf.arn
  }
}