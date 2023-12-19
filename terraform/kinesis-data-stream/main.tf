provider "aws" {
  region = "us-west-2"  # Replace with your desired region
}

data "aws_iam_user" "chris" {
    user_name = "chris"
}

resource "aws_iam_access_key" "chris_kinesis_key" {
  user = data.aws_iam_user.chris.user_name
}

resource "aws_iam_user_policy_attachment" "chris_kinesis_policy" {
    user       = data.aws_iam_user.chris.user_name
    policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisReadOnlyAccess"
}

output "access_key_id" {
  value = aws_iam_access_key.chris_kinesis_key.id
}

output "secret_access_key" {
  value = aws_iam_access_key.chris_kinesis_key.secret
  sensitive = true
}
