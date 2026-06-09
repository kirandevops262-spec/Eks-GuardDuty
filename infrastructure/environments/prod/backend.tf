# infrastructure/environments/dev/backend.tf

terraform {
  backend "s3" {
    bucket         = "eks-mcp-tfstate"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "eks-mcp-tfstate-lock"
    encrypt        = true
  }
}
