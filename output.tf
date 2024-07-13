output "route53_zone_id" {
  value = data.aws_route53_zone.selected.id
}

output "route53_zone_name" {
  value = data.aws_route53_zone.selected.name
}

