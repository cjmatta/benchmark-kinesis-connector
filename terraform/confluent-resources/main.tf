# Configure the Confluent Provider
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.55.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key    # optionally use CONFLUENT_CLOUD_API_KEY env var
  cloud_api_secret = var.confluent_cloud_api_secret # optionally use CONFLUENT_CLOUD_API_SECRET env var
}

# use the existing confluent env 'default'
data "confluent_environment" "default_env" {
    id = var.confluent_cloud_environment_id
}

# create a new cluster in the existing confluent env 'default'
resource "confluent_kafka_cluster" "kinesis_test" {
    display_name = "kinesis-test"
    availability = "MULTI_ZONE"
    cloud = "AWS"
    region = var.aws_region

    dedicated {
        cku = 2
    }

    environment {
        id = data.confluent_environment.default_env.id
    }

    lifecycle {
        prevent_destroy = false
    }
}
resource "confluent_service_account" "kinesis_test_manager_sa" {
    display_name = "kinesis-test-sa-manager"
    description = "kinesis-test-sa-manager"
}

resource "confluent_role_binding" "kinesis_test_manager_role" {
    principal = "User:${confluent_service_account.kinesis_test_manager_sa.id}"
    role_name = "CloudClusterAdmin"
    crn_pattern = "${confluent_kafka_cluster.kinesis_test.rbac_crn}"
}

resource "confluent_api_key" "kinesis_test_manager_api_key" {
    display_name = "kinesis-test-api-key-manager"
    description = "kinesis-test-api-key-manager"
    owner { 
        id = confluent_service_account.kinesis_test_manager_sa.id
        api_version = confluent_service_account.kinesis_test_manager_sa.api_version
        kind = confluent_service_account.kinesis_test_manager_sa.kind
    }

    managed_resource { 
        id = confluent_kafka_cluster.kinesis_test.id
        api_version = confluent_kafka_cluster.kinesis_test.api_version
        kind = confluent_kafka_cluster.kinesis_test.kind

        environment {
            id = data.confluent_environment.default_env.id
        }

    }

    depends_on = [ confluent_role_binding.kinesis_test_manager_role ]
}

# create a topic for the kinesis source connector 
resource "confluent_kafka_topic" "kinesis_test_topic" {
    kafka_cluster {
        id = confluent_kafka_cluster.kinesis_test.id
    }
    rest_endpoint = confluent_kafka_cluster.kinesis_test.rest_endpoint
    credentials {
      key = confluent_api_key.kinesis_test_manager_api_key.id
      secret = confluent_api_key.kinesis_test_manager_api_key.secret
    }
    
    topic_name = "kinesis-test-topic"
    partitions_count = 16
}

# create service account for the kinesis source connector
resource "confluent_service_account" "kinesis_test_sa" {
    display_name = "kinesis-test-sa"
    description = "kinesis-test-sa"
}

# create a new role for the kinesis source connector
resource "confluent_role_binding" "kinesis_test_role" {
    principal = "User:${confluent_service_account.kinesis_test_sa.id}"
    role_name = "DeveloperWrite"
    crn_pattern = "${confluent_kafka_cluster.kinesis_test.rbac_crn}/kafka=${confluent_kafka_cluster.kinesis_test.id}/topic=${confluent_kafka_topic.kinesis_test_topic.topic_name}"
}

# create api key
resource "confluent_api_key" "kinesis_test_api_key" {
    display_name = "kinesis-test-api-key"
    description = "kinesis-test-api-key"
    owner { 
        id = confluent_service_account.kinesis_test_sa.id
        api_version = confluent_service_account.kinesis_test_sa.api_version
        kind = confluent_service_account.kinesis_test_sa.kind
    }

    managed_resource { 
        id = confluent_kafka_cluster.kinesis_test.id
        api_version = confluent_kafka_cluster.kinesis_test.api_version
        kind = confluent_kafka_cluster.kinesis_test.kind

        environment {
            id = data.confluent_environment.default_env.id
        }

    }


    depends_on = [
        confluent_role_binding.kinesis_test_role
    ]
}

# create a new kinesis source connector
resource "confluent_connector" "kinesis_source" {
    environment {
        id = data.confluent_environment.default_env.id
    }

    kafka_cluster {
        id = confluent_kafka_cluster.kinesis_test.id
    }

    config_sensitive = {
        "aws.access.key.id" = var.aws_access_key_id
        "aws.secret.key.id" = var.aws_secret_access_key
    }

    config_nonsensitive = {
        "connector.class" = "KinesisSource"
        "name" = "kinesis-source-test"
        "kafka.auth.mode" = "SERVICE_ACCOUNT"
        "kafka.service.account.id" = confluent_service_account.kinesis_test_sa.id
        "kafka.topic" = confluent_kafka_topic.kinesis_test_topic.topic_name
        "output.data.format" = "JSON"
        "tasks.max" = "16"
        "kinesis.stream" = var.kinesis_stream_name
    }
}