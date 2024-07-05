resource "random_id" "server" {
  byte_length = 4
}

module "cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.4.0"

  aliases = ["${local.name}-cloudfront.${data.aws_route53_zone.selected.name}"]

  comment             = "Tsang Han's awesome CloudFront with Route 53 - ${local.random.Name}"
  enabled             = true
  is_ipv6_enabled     = false
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false
  default_root_object = "home.html"
  tags                = local.common_tags

  create_origin_access_identity = false

  origin = {
    something = {
      domain_name = "jaz-cloudfront-demo.s3.ap-southeast-1.amazonaws.com"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols   = ["TLSv1.1", "TLSv1.2"]
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "something"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }

  viewer_certificate = {
    acm_certificate_arn = "${data.aws_acm_certificate.issued.arn}"
    ssl_support_method  = "sni-only"
    cloudfront_default_certificate = false
    minimum_protocol_version = "TLSv1.2_2021"
  }

}

data "aws_route53_zone" "selected" {
  name = "sctp-sandbox.com."
}

resource "aws_route53_record" "tsanghan-ce6" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${local.name}-cloudfront.${data.aws_route53_zone.selected.name}"
  type    = "A"

  alias {
    name = "${module.cdn.cloudfront_distribution_domain_name}"
    zone_id = "${module.cdn.cloudfront_distribution_hosted_zone_id}"
    evaluate_target_health = false
  }

}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name  = "${data.aws_route53_zone.selected.name}"
  zone_id      = "${data.aws_route53_zone.selected.zone_id}"

  validation_method = "DNS"

  subject_alternative_names = [
    "${local.name}-cloudfront.${data.aws_route53_zone.selected.name}",
  ]

  wait_for_validation = true

  tags = local.common_tags
}