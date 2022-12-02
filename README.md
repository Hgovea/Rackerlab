# Rackerlab
Launch a simple web site in a load balanced, highly available and highly resilient manner utilizing automation
and AWS best practices.

VPC with private/public subnets and all required dependent infrastructure matching AWS highly available
best practices (DO NOT USE THE DEFAULT VPC)

• ELB to be used to register web server instances

• Include a simple health check to make sure the webservers are responding

• The health check should automatically
Auto Scaling Group and Launch Configuration that launches EC2 instances and registers them to the ELB

• Establish a minimum, maximum, and desired server count based on AWS best practices that scales up /
down based on a metric of your choice (and be able to demonstrate a scaling event)

• Security Group allowing HTTP traffic to load balancer from anywhere (not directly to the instance(s))

• Security Group allowing only HTTP traffic from the load balancer to the instance(s)

• Remote management ports such as SSH and RDP must not be open to the world

• Some kind of automation or scripting that achieves the following:

• Install a webserver (your choice – Apache and Nginx are common examples)

• Deploys a simple “hello world” page for the webserver to serve up

• Can be written in the computer language of your choice (HTML, PHP, etc)

• Can be sourced from the location of your choice (S3, cookbook file / template, etc)

• Must include the server’s hostname in the “hello world” web page presented to the user

• All AWS resources must be created using Terraform or CloudFormation

• No resources may be created or managed by hand / manually other than EC2 SSH keys 
