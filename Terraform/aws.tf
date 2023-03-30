
resource "random_id" "vpc_display_id" {
    byte_length = 4
}
# ------------------------------------------------------
# VPC
# ------------------------------------------------------
resource "aws_vpc" "main" { 
    cidr_block = var.vpc_cidr
    tags = {
        Name = "iot-blog-${random_id.vpc_display_id.hex}"
    }
}

# ------------------------------------------------------
# Public SUBNETS
# ------------------------------------------------------

resource "aws_subnet" "public_subnets" {
    count = 3
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.${count.index+1}.0/24"
    map_public_ip_on_launch = true
    tags = {
        Name = "iot-demo-public-${count.index}-${random_id.vpc_display_id.hex}"
    }
}


# ------------------------------------------------------
# Private SUBNETS
# ------------------------------------------------------

resource "aws_subnet" "private_subnets" {
    count = 3
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.${count.index+10}.0/24"
    map_public_ip_on_launch = false
    tags = {
        Name = "iot-demo-private-${count.index}-${random_id.vpc_display_id.hex}"
    }
}
# ------------------------------------------------------
# IGW
# ------------------------------------------------------
resource "aws_internet_gateway" "igw" { 
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "iot-demo-${random_id.vpc_display_id.hex}"
    }
}



# ------------------------------------------------------
# EIP
# ------------------------------------------------------

resource "aws_eip" "eip" {
  vpc      = true
}

# ------------------------------------------------------
# NAT
# ------------------------------------------------------

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.eip.id
  subnet_id = aws_subnet.public_subnets[1].id
  tags = {
    Name = "iot-demo-${random_id.vpc_display_id.hex}"
  }
}


# ------------------------------------------------------
# ROUTE TABLE
# ------------------------------------------------------
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        Name = "iot-demo-${random_id.vpc_display_id.hex}"
    }
}

resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.natgw.id
    }
    tags = {
        Name = "iot-demo-${random_id.vpc_display_id.hex}"
    }
}

resource "aws_route_table_association" "pub_subnet_associations" {
    count = 3
    subnet_id = aws_subnet.public_subnets[count.index].id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "pri_subnet_associations" {
    count = 3
    subnet_id = aws_subnet.private_subnets[count.index].id
    route_table_id = aws_route_table.private_route_table.id
}



# ------------------------------------------------------
# SG
# ------------------------------------------------------

resource "aws_security_group" "sg" {
  name        = "iot-demo-${random_id.vpc_display_id.hex}"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow_tls"
  }
}

# ------------------------------------------------------
# Secrets Manager
# ------------------------------------------------------

# Creating a AWS Secret for Confluent User 
resource "aws_secretsmanager_secret" "service_user" {
  name        = "iot-demo-confluent-secret-${random_id.vpc_display_id.hex}"
  description = "Service Account Username for the API"
}

resource "aws_secretsmanager_secret_version" "service_user" {
  secret_id     = aws_secretsmanager_secret.service_user.id
  secret_string = jsonencode({"confluent_key": "${confluent_api_key.app-manager-kafka-api-key.id}", "confluent_secret": "${confluent_api_key.app-manager-kafka-api-key.secret}"})
}


# ------------------------------------------------------
# IAM Roles
# ------------------------------------------------------

# For IOT Core

resource "aws_iam_role_policy" "secrets_policy" {
  name = "secrets_manager_policy-${random_id.vpc_display_id.hex}"
  role = aws_iam_role.Iot_role.id
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "Iot_role" {
  name = "iot-demo-iot-role-${random_id.vpc_display_id.hex}"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSIoTThingsRegistration",
  "arn:aws:iam::aws:policy/service-role/AWSIoTLogging",
  "arn:aws:iam::aws:policy/service-role/AWSIoTRuleActions",
  "arn:aws:iam::aws:policy/AmazonEC2FullAccess"]  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "iot.amazonaws.com"
        }
      },
    ]
  })
}

# For Lambda function

resource "aws_iam_role" "Lambda_role" {
  name = "iot-demo-lambda-role-${random_id.vpc_display_id.hex}"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSIoTDataAccess",
  "arn:aws:iam::aws:policy/service-role/AWSIoTLogging",
  "arn:aws:iam::aws:policy/AWSIoTFullAccess",
  "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  "arn:aws:iam::aws:policy/AWSIoTConfigAccess"]
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# ------------------------------------------------------
# IoT Rule
# ------------------------------------------------------

resource "aws_iot_topic_rule" "rule" {
  name        = "iot_demo_${random_id.vpc_display_id.hex}"
  description = "Rule to Confluent"
  enabled     = true
  sql         = "SELECT * FROM 'topic/test'"
  sql_version = "2016-03-23"
  kafka {
    client_properties = {
      "acks"                = "1"
      "bootstrap.servers"   = "${confluent_kafka_cluster.cluster.bootstrap_endpoint}"
      "compression.type"    = "none"
      "security.protocol"   = "SASL_SSL"
      "key.serializer"    = "org.apache.kafka.common.serialization.StringSerializer"
      "value.serializer"   = "org.apache.kafka.common.serialization.ByteBufferSerializer"
      "sasl.mechanism"      = "PLAIN"
      "sasl.plain.username" = "$${get_secret('iot-demo-confluent-secret-${random_id.vpc_display_id.hex}', 'SecretString', 'confluent_key', '${aws_iam_role.Iot_role.arn}')}"
      "sasl.plain.password" = "$${get_secret('iot-demo-confluent-secret-${random_id.vpc_display_id.hex}', 'SecretString', 'confluent_secret', '${aws_iam_role.Iot_role.arn}')}"
    }
    topic           = var.confluent_topic_name
    destination_arn = aws_iot_topic_rule_destination.topic_rule_destination.arn
  }
}

resource "aws_iot_topic_rule_destination" "topic_rule_destination" {
  vpc_configuration {
    role_arn        = aws_iam_role.Iot_role.arn
    security_groups = [aws_security_group.sg.id]
    subnet_ids      = aws_subnet.private_subnets[*].id
    vpc_id          = aws_vpc.main.id
  }
}

# ------------------------------------------------------
# Chaos Lambda
# ------------------------------------------------------



resource "aws_lambda_function" "chaos_lambda" {
  function_name = "iot-demo-chaos-lambda${random_id.vpc_display_id.hex}"
  filename         = data.archive_file.chaos_lambda_zip.output_path
  source_code_hash = data.archive_file.chaos_lambda_zip.output_base64sha256
  description = "Allows you to simulate out-of-bounds emission values on your Air Quality Sensor Thing."
  handler = "chaos_lambda.lambda_handler"
  role = aws_iam_role.Lambda_role.arn
  timeout = 900
  runtime = "python3.9"
}


data "archive_file" "chaos_lambda_zip" {
  type        = "zip"
  source_file = "chaos_lambda.py"
  output_path = "chaos_lambda.zip"
}

# ------------------------------------------------------
# Fix Lambda
# ------------------------------------------------------


resource "aws_lambda_function" "fix_lambda" {
  function_name = "iot-demo-fix-lambda${random_id.vpc_display_id.hex}"
  filename         = data.archive_file.fix_lambda_zip.output_path
  source_code_hash = data.archive_file.fix_lambda_zip.output_base64sha256
  description = "Allows you to fix out-of-bounds emission values on your Air Quality Sensor Thing."
  handler = "fix_lambda.lambda_handler"
  role = aws_iam_role.Lambda_role.arn
  timeout = 900
  runtime = "python3.9"
}

data "archive_file" "fix_lambda_zip" {
  type        = "zip"
  source_file = "fix_lambda.py"
  output_path = "fix_lambda.zip"
}
