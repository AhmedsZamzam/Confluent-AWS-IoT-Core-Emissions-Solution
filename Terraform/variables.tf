variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)."
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret."
  type        = string
  sensitive   = true
}

variable "aws_key" {
  description = "AWS API Key (with Lmabda Invoke Permission)."
  type        = string
}

variable "aws_secret" {
  description = "AWS API Secret."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The region of Confluent Cloud Network."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC Cidr to be created"
  type        = string
}

variable "confluent_topic_name" {
  description = "Topic name for solution"
  type        = string
}


variable "confluent_output_topic_name" {
  description = "Topic name for solution"
  type        = string
}




