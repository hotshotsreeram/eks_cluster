variable "aws_zone1"{
  type = string
  description = "available aws zones"
}

variable "aws_zone2"{
  type = string
  description = "available aws zones"
}

variable "profile"{
  type = string
  description = "profile name"
}

variable "private_subnet_tags1"{
	type= string
	description= "tags for private subnet"
}

variable "vpc_tags"{
	type= string
	description= "tags for vpc"
}

variable "custom_vpc" {
  type        = string
  description = "custom vpc ip cidr block"
}

variable "private_subnet_tags2"{
	type= string
	description= "tags for private subnet"
}

variable "private_subnet1" {
  type        = string
  description = "private subnet ip cidr block"
}

variable "private_subnet2" {
  type        = string
  description = "private subnet ip cidr block"
}


variable "aws_region" {
  type        = string
  description = "aws region for the instance and lb"
}

variable "public_subnet_tags"{
	type= string
	description="tags for public subnet"
}

variable "public_subnet_tags2"{
	type= string
	description="tags for public subnet"
}

variable "internet_gateway_tags"{
	type= string
	description= "tags for internet gateway"
}

variable "public_subnet" {
  type        = string
  description = "public subnet ip cidr block"
}

variable "public_subnet2" {
  type        = string
  description = "public subnet ip cidr block"
}