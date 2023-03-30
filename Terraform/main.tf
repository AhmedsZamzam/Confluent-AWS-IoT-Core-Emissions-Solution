resource "random_id" "env_display_id" {
    byte_length = 4
}

# ------------------------------------------------------
# ENVIRONMENT
# ------------------------------------------------------

resource "confluent_environment" "staging" {
  display_name = "iot-blog-${random_id.env_display_id.hex}"
}


# ------------------------------------------------------
# SCHEMA REGISTRY
# ------------------------------------------------------
data "confluent_schema_registry_region" "sr_region" {
    cloud = "AWS"
    region = "us-east-2"
    package = "ESSENTIALS"
}
resource "confluent_schema_registry_cluster" "sr" {
    package = data.confluent_schema_registry_region.sr_region.package
    environment {
        id = confluent_environment.staging.id 
    }
    region {
        id = data.confluent_schema_registry_region.sr_region.id
    }
}

# ------------------------------------------------------
# KAFKA
# ------------------------------------------------------

resource "confluent_kafka_cluster" "cluster" {
  display_name = "iot-blog"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = var.region
  standard {}
  environment {
    id = confluent_environment.staging.id
  }
}


# ------------------------------------------------------
# SERVICE ACCOUNTS
# ------------------------------------------------------

// 'app-manager' service account is required in this configuration to create 'orders' topic and assign roles
// to 'app-producer' and 'app-consumer' service accounts.
resource "confluent_service_account" "app-manager" {
  display_name = "app-manager-${random_id.env_display_id.hex}"
  description  = "Service account to manage  Kafka cluster"
}


resource "confluent_service_account" "connectors" {
    display_name = "connector-sa-${random_id.env_display_id.hex}"
    description = "Service account for connectors"
}


# ------------------------------------------------------
# ROLE BINDINGS
# ------------------------------------------------------

resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.cluster.rbac_crn
}


# ------------------------------------------------------
# Connectors ACLS
# ------------------------------------------------------

resource "confluent_kafka_acl" "app-connector-describe-on-cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.connectors.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-read-on-target-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "IOT_"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.connectors.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}


resource "confluent_kafka_acl" "app-connector-write-to-data-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "IOT_"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.connectors.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-create-on-dlq-lcc-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "dlq-lcc"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.connectors.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-write-on-dlq-lcc-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "dlq-lcc"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.connectors.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-create-on-success-lcc-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "success-lcc"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.connectors.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-write-on-success-lcc-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "success-lcc"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.connectors.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-create-on-error-lcc-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "error-lcc"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.connectors.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-write-on-error-lcc-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "error-lcc"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.connectors.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-read-on-connect-lcc-group" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  resource_type = "GROUP"
  resource_name = "connect-lcc"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.connectors.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}


# ------------------------------------------------------
# API KEYS
# ------------------------------------------------------

resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-kafka-api-key"
  disable_wait_for_ready = true
  description  = "Kafka API Key that is owned by 'app-manager' service account"

  # Set optional `disable_wait_for_ready` attribute (defaults to `false`) to `true` if the machine where Terraform is not run within a private network
  # disable_wait_for_ready = true

  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.cluster.id
    api_version = confluent_kafka_cluster.cluster.api_version
    kind        = confluent_kafka_cluster.cluster.kind

  environment {
      id = confluent_environment.staging.id
    }
  }

  # The goal is to ensure that
  # 1. confluent_role_binding.app-manager-kafka-cluster-admin is created before
  # confluent_api_key.app-manager-kafka-api-key is used to create instances of
  # confluent_kafka_topic resource.
  # 2. Kafka connectivity through AWS VPC Peering is setup.
  depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin
  ]
}


resource "confluent_api_key" "connector_keys" {
    display_name = "connectors-api-key-${random_id.env_display_id.hex}"
    description = "Connector API Key"
    owner {
        id = confluent_service_account.connectors.id 
        api_version = confluent_service_account.connectors.api_version
        kind = confluent_service_account.connectors.kind
    }
    managed_resource {
        id = confluent_kafka_cluster.cluster.id 
        api_version = confluent_kafka_cluster.cluster.api_version
        kind = confluent_kafka_cluster.cluster.kind
        environment {
            id = confluent_environment.staging.id
        }
    }
}



# ------------------------------------------------------
# KAFKA Topic
# ------------------------------------------------------

// Provisioning Kafka Topics requires access to the REST endpoint on the Kafka cluster
// If Terraform is not run from within the private network, this will not work
resource "confluent_kafka_topic" "orders" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  topic_name    = var.confluent_topic_name
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}


# ------------------------------------------------------
# KsqlDB Cluster
# ------------------------------------------------------

resource "confluent_ksql_cluster" "ksql" {
  display_name = "iot-blog"
  csu          = 1
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }
  credential_identity {
    id = confluent_service_account.app-manager.id
  }
  environment {
    id = confluent_environment.staging.id
  }
  depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin
  ]
}



# ------------------------------------------------------
# Lambda Sink Connector
# ------------------------------------------------------


resource "confluent_connector" "lambda_sink" {
    environment {
        id = confluent_environment.staging.id 
    }
    kafka_cluster {
        id = confluent_kafka_cluster.cluster.id
    }
    status = "RUNNING"
    config_nonsensitive = {
      "connector.class": "LambdaSink",
      "name": "Iot_blog_LambdaSinkConnector_0",
      "topics": "IOT_DEMO_NOX_LATEST_AVERAGE",
      "input.data.format": "JSON",
      "kafka.auth.mode": "SERVICE_ACCOUNT",
      "kafka.service.account.id" = confluent_service_account.connectors.id,
      "aws.lambda.function.name" = aws_lambda_function.fix_lambda.function_name,
      "aws.lambda.invocation.type" = "async",
      "aws.access.key.id": var.aws_key,
      "aws.secret.access.key": var.aws_secret,
      "tasks.max": "1"
    }
    depends_on = [
        confluent_kafka_acl.app-connector-describe-on-cluster,
        confluent_kafka_acl.app-connector-read-on-target-topic,
        confluent_kafka_acl.app-connector-create-on-dlq-lcc-topics,
        confluent_kafka_acl.app-connector-write-on-dlq-lcc-topics,
        confluent_kafka_acl.app-connector-write-to-data-topics,
        confluent_kafka_acl.app-connector-create-on-success-lcc-topics,
        confluent_kafka_acl.app-connector-write-on-success-lcc-topics,
        confluent_kafka_acl.app-connector-create-on-error-lcc-topics,
        confluent_kafka_acl.app-connector-write-on-error-lcc-topics,
        confluent_kafka_acl.app-connector-read-on-connect-lcc-group,
  ]
}