terraform {
  backend "s3" {
    bucket       = "ittalo-terraform-state-cloud-security-2026"
    key          = "terraform-vpc-lab/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
