provider "aws" {
  region = local.region
  alias  = "ase1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "ue1"
}

provider "random" {}
