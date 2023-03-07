data "aws_route53_zone" "pufferfish" {
  name = local.domain
}

resource "aws_route53_record" "pufferfish" {
  for_each = toset([local.domain, "www.${local.domain}"])

  zone_id = data.aws_route53_zone.pufferfish.id
  type    = "A"
  name    = each.value

  alias {
    name                   = aws_lb.pufferfish.dns_name
    zone_id                = aws_lb.pufferfish.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "pufferfish_certificate_validation" {
  for_each = {
    for dvo in aws_acm_certificate.pufferfish.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.pufferfish.id
}
