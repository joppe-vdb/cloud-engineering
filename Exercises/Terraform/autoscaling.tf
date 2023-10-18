#Get AMI ID for latest Amazon Linux 2 AMI
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

module "asg" {
  source = "terraform-aws-modules/autoscaling/aws" 
  image_id = data.aws_ami.amazon-linux-2.id

  instance_type = "t2.micro"

  name              = "webservers-asg"
  health_check_type = "EC2"
  #the EC2 VMs should be spread between us-east1a and us-east1b
  #availability_zones = ["us-east-1a", "us-east-1b"]
  desired_capacity   = 2
  max_size           = 4
  min_size           = 1
  vpc_zone_identifier  = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
  depends_on = [module.vpc]
  user_data = base64encode(<<EOF
		#!/bin/bash
		yum -update -y
		yum install httpd -y
		systemctl start httpd
		systemctl enable httpd
		echo '<html><h1>Joppe Van den Broeck</h1></html>' > /var/www/html/index.html
		EOF

   )
                      
}


module  "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "autoscaling_vpc"
  cidr = "10.0.0.0/16"
  azs = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway =  true
}


module "alb" {
  source="terraform-aws-modules/alb/aws"
  version = "~> 8.0"
  name = "autoscaling-alb"
  load_balancer_type= "application"
  vpc_id = module.vpc.vpc_id
  subnets = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  security_groups = [aws_security_group.alb_sg.id]  

  http_tcp_listeners = [
   {
    port = 80
    protocol = "HTTP"
    target_group_index = 0
   },
  ]

  target_groups = [
    {
      name_prefix =  "tg-"
      backend_protocol = "HTTP"
      backend_port = 80
      target_type = "instance"
    },
  ]
}


resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = module.asg.autoscaling_group_name
  lb_target_group_arn = module.alb.target_group_arns[0]
}


resource "aws_security_group" "alb_sg" {
  name = "alb_sg"
  vpc_id = module.vpc.vpc_id
  
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "ec2_sg" {
  name =  "ec2_sg"
  vpc_id = module.vpc.vpc_id
  
  ingress {
    from_port =  80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




