terraform {
  backend "s3" {
    bucket         = "terraform-state-145405817961-us-east-1"
    key            = "taskmanager/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    profile        = "demo-sa"
  }
}
