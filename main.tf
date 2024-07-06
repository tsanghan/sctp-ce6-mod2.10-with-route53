module "cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.4.0"

  aliases = ["${local.name}-cloudfront.${data.aws_route53_zone.selected.name}"]

  comment                      = "Tsang Han's awesome CloudFront with Route 53 & TLS Certificcate - ${local.random.Name}"
  enabled                      = true
  is_ipv6_enabled              = false
  price_class                  = "PriceClass_All"
  retain_on_delete             = false
  wait_for_deployment          = false
  default_root_object          = "index.html"
  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = "CloudFront access to S3"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }
  tags = local.common_tags

  origin = {
    # something = {
    #   domain_name = "${module.s3_bucket.s3_bucket_bucket_regional_domain_name}"
    #   origin_access_control = "s3_oac"
    #   custom_origin_config = {
    #     http_port              = 80
    #     https_port             = 443
    #     origin_protocol_policy = "match-viewer"
    #     origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    #   }
    # }
    something = {
      domain_name           = "${module.s3_bucket.s3_bucket_bucket_regional_domain_name}"
      origin_access_control = "s3_oac"
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
    acm_certificate_arn            = "${module.acm.acm_certificate_arn}"
    ssl_support_method             = "sni-only"
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
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
    name                   = module.cdn.cloudfront_distribution_domain_name
    zone_id                = module.cdn.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = false
  }

}

resource "aws_route53_record" "tsanghan-ce6-caa" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = data.aws_route53_zone.selected.name
  type    = "CAA"
  ttl     = 300
  records = ["0 issue \"amazon.com\""]
}

module "acm" {
  providers = {
    aws = aws.ue1
  }
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = "${local.name}-cloudfront.${data.aws_route53_zone.selected.name}"
  zone_id     = data.aws_route53_zone.selected.zone_id

  validation_method = "DNS"

  subject_alternative_names = [
    "${local.name}-cloudfront.${data.aws_route53_zone.selected.name}",
  ]

  wait_for_validation = true

  tags = local.common_tags
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid = "AllowCloudFrontServicePrincipalReadOnly"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${module.s3_bucket.s3_bucket_arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["${module.cdn.cloudfront_distribution_arn}"]
    }
  }

}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket                  = local.bucket_name
  force_destroy           = true
  attach_policy           = true
  policy                  = data.aws_iam_policy_document.bucket_policy.json
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  tags                    = local.common_tags

}

module "template_files" {
  source   = "hashicorp/dir/template"
  base_dir = "static-website"
  template_vars = {
    # Pass in any values that you wish to use in your templates.
    vpc_id = "vpc-abc123"
  }
}

module "s3-bucket_object" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "4.1.2"

  for_each     = module.template_files.files
  bucket       = module.s3_bucket.s3_bucket_id
  key          = each.key
  file_source  = each.value.source_path
  content_type = each.value.content_type
  etag         = each.value.digests.md5
}


