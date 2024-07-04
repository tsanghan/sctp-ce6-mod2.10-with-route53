terraform {
  backend "s3" {
    bucket = "sctp-ce6-tfstate"
    key    = "tsanghan-ce6-mod2_10_with_route53.tfstate"
    region = "ap-southeast-1"
  }
}