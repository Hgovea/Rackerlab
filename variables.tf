
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "image_id" {
  type    = string
  default = "ami-0b0dcb5067f052a63"
}

variable "flavor" {
  type    = string
  default = "t2.micro"
}

variable "ec2_instance_port" {
  type    = number
  default = 80
}

