# Securityy groups for load balancer
resource "aws_security_group" "alb-sec-group" {
  name        = "alb-sec-group"
  description = "Security Group for the ELB (ALB)"
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "asg_sec_group" {
  name        = "asg_sec_group"
  description = "Security Group for the ASG"
  tags = {
    name = "name"
  }
  // Allow ALL outbound traffic
  egress {
    from_port   = 0
    protocol    = "-1" // ALL Protocols
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  // Allow Inbound traffic from the ELB Security-Group
  ingress {
    from_port       = 80
    protocol        = "tcp"
    to_port         = 80
    security_groups = [aws_security_group.alb-sec-group.id] // Allow Inbound traffic from the ALB Sec-Group
  }
}
# EC2 template
resource "aws_launch_configuration" "ec2_template" {
  image_id        = var.image_id
  instance_type   = var.flavor
  user_data       = <<-EOF
            #!/bin/bash
            yum update -y
            amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
            yum install -y httpd mariadb-server
            systemctl start httpd
            systemctl enable httpd
            usermod -a -G apache ec2-user
            chown -R ec2-user:apache /var/www
            chmod 2775 /var/www
            find /var/www -type d -exec chmod 2775 {} \;
            find /var/www -type f -exec chmod 0664 {} \;
            echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
            EOF
  security_groups = [aws_security_group.asg_sec_group.id]
  // If the launch_configuration is modified:
  // --> Create New resources before destroying the old resources
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}



// Create the ASG
// https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html

resource "aws_autoscaling_group" "Practice_ASG" {
  max_size                  = 5
  min_size                  = 2
  launch_configuration      = aws_launch_configuration.ec2_template.name
  health_check_grace_period = 300 // Time after instance comes into service before checking health.

  health_check_type = "ELB" // ELB or Ec2 (Default):
  // EC2 --> Minimal health check - consider the vm unhealthy if the Hypervisor says the vm is completely down
  // ELB --> Instructs the ASG to use the "target's group" health check

  vpc_zone_identifier = data.aws_subnet_ids.default.ids // A list of subnet IDs to launch resources in.
  // We specified all the subnets in the default vpc

  target_group_arns = [aws_lb_target_group.asg.arn]

  tag {
    key                 = "name"
    propagate_at_launch = false
    value               = "Practice_ASG"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Create Applicatiion LoadBalancer
resource "aws_lb" "ELB" {
  name               = "Rack-alb"
  load_balancer_type = "application"

  # Subnets
  subnets         =  data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb-sec-group.id]
}

// https://www.terraform.io/docs/providers/aws/r/lb_listener.html
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ELB.arn // Amazon Resource Name (ARN) of the load balancer
  port              = 80
  protocol          = "HTTP"

  // By default, return a simple 404 page
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

// create a target group for your ASG

resource "aws_lb_target_group" "asg" {
  name     = "asg-example"
  port     = var.ec2_instance_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

// https://www.terraform.io/docs/providers/aws/r/lb_listener_rule.html
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

## Stopped here --> How does the target group know which EC2 Instances to send requests to?
## in (crate ELB (ALB)) note





