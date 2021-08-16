module "vpc" {
  source = "./modules/networking"
}

resource "aws_instance" "web01" {
  ami                         = "ami-04db49c0fb2215364"
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.pub_sub_ids[0]
  associate_public_ip_address = true
  user_data                   = file("./userdata.sh")
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  aws_iam_instance_profile    = aws_iam_instance_profile.web_role.name
  tags = {
    Name = "web01-instance-${terraform.workspace}"
  }
}

module "elb" {
  source    = "./modules/elb-classic"
  subnets   = module.vpc.pub_sub_ids
  instances = [aws_instance.web01.id]
  vpc_id    = module.vpc.vpc_id
  listeners = {
    "80" = {
      instance_port     = 80
      instance_protocol = "http"
      lb_port           = 80
      lb_protocol       = "http"
    }
  }
}

module "rds" {
  source  = "./modules/rds"
  subnets = module.vpc.priv_sub_ids
}

resource "aws_security_group" "web_sg" {
  name        = "a${var.app_name}-${terraform.workspace}-web_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-${terraform.workspace}-web_sg"
  }
}