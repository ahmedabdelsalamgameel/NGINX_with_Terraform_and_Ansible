terraform {
  backend "s3" {
    bucket         = "mybackbuck"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terra-lock-state"
  }
}