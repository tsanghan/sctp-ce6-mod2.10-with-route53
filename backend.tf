terraform {
  backend "s3" {
    bucket = "sctp-ce6-tfstate"
    key    = "tsanghan-ce6-mod2_10-with-route53-&-TLS-Certificate.tfstate"
    region = "ap-southeast-1"
  }
}

