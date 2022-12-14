resource "aws_security_group" "alb-sec-group" {
  name        = "alb-sec-group"
  description = "Security Group for the ELB (ALB)"
  vpc_id      = aws_vpc.main.id

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
  vpc_id      = aws_vpc.main.id

  tags = {
    name = "name"
  }
  # Allow ALL outbound traffic
  egress {
    from_port   = 0
    protocol    = "-1" // ALL Protocols
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow Inbound traffic from the ELB Security-Group
  ingress {
    from_port       = 80
    protocol        = "tcp"
    to_port         = 80
    security_groups = [aws_security_group.alb-sec-group.id] // Allow Inbound traffic from the ALB Sec-Group
  }
}

# Create the Launch configuration so that the ASG can use it to launch EC2 instances
resource "aws_launch_configuration" "ec2_template" {
  image_id        = var.image_id
  instance_type   = var.flavor
  user_data       = <<-EOF
            #!/bin/bash
           yum update -y
           yum install -y httpd
           systemctl start httpd.service
           systemctl enable httpd.service
           EC2_AVAIL_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
           echo "<h1>Hello World From Rokkitt at at $(hostname -f) in AZ $EC2_AVAIL_ZONE </h1>" > /var/www/html/index.html
            EOF

  }
 
data "aws_vpc" "main" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.main.id
}



# Create the ASG
resource "aws_autoscaling_group" "Practice_ASG" {
  max_size                  = 5
  min_size                  = 2
  launch_configuration      = aws_launch_configuration.ec2_template.name
  health_check_grace_period = 300

  health_check_type = "ELB"
  
  # We specified all the subnets in the custom vpc
  vpc_zone_identifier = ["${aws_subnet.public.id}", "${aws_subnet.public2.id}"]


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

# Create Application LoadBalancer 
resource "aws_lb" "ELB" {
  name               = "racker-alb"
  load_balancer_type = "application"

  # Subnets
  subnets         = ["${aws_subnet.public.id}", "${aws_subnet.public2.id}"]
  security_groups = [aws_security_group.alb-sec-group.id]
}

# Loadbalancer Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ELB.arn
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

# create a target group for your ASG

resource "aws_lb_target_group" "asg" {
  name     = "asg-group"
  port     = var.ec2_instance_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

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

#LB listener rule
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








