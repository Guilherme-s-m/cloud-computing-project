terraform {
  backend "s3" {
    bucket         = "guilhermesm9-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"  # substitua pela região desejada
    encrypt        = true
  }
}
