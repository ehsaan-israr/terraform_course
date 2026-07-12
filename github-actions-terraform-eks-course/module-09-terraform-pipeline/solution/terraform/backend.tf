terraform {
  backend "s3" {
    # Partial configuration — bucket, key, region, dynamodb_table supplied via backend.hcl
    encrypt = true
  }
}
