locals {
  region = "us-east-1"

  name = "tsanghan-ce6"
  common_tags = {
    Name = "${local.name}"
  }

  random = {
    Name = "${random_id.server.hex}"
  }
}