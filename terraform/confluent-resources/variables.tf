variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key"
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID"
}

variable "aws_secret_access_key" {
    description = "AWS Access Key Secret"
}

variable "aws_region" {
    description = "AWS Region"
    default = "us-west-2"
}

variable "confluent_cloud_environment_id" {
    description = "Confluent Cloud Environment ID"
}

variable "kinesis_stream_name" {
    description = "Kinesis Stream Name"
    default = "DemoStream"
}