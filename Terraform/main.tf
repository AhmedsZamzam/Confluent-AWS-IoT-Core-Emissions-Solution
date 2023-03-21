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
# KAFKA
# ------------------------------------------------------

resource "confluent_kafka_cluster" "dedicated" {
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


# ------------------------------------------------------
# ROLE BINDINGS
# ------------------------------------------------------

resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.dedicated.rbac_crn
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
    id          = confluent_kafka_cluster.dedicated.id
    api_version = confluent_kafka_cluster.dedicated.api_version
    kind        = confluent_kafka_cluster.dedicated.kind

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



# ------------------------------------------------------
# KAFKA Topic
# ------------------------------------------------------

// Provisioning Kafka Topics requires access to the REST endpoint on the Kafka cluster
// If Terraform is not run from within the private network, this will not work
resource "confluent_kafka_topic" "orders" {
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }
  topic_name    = var.confluent_topic_name
  rest_endpoint = confluent_kafka_cluster.dedicated.rest_endpoint
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
    id = confluent_kafka_cluster.dedicated.id
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