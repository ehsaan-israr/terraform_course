# Backend values are supplied during terraform init so this app can be reused
# across students, accounts, and environments.
#
# Example:
# terraform init \
#   -backend-config="bucket=<state_bucket_name>" \
#   -backend-config="key=state-management/dev/terraform.tfstate" \
#   -backend-config="region=us-east-1" \
#   -backend-config="dynamodb_table=<lock_table_name>" \
#   -backend-config="encrypt=true"
terraform {
  backend "s3" {}
}

