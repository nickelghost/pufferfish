resource "aws_acm_certificate" "pufferfish" {
  domain_name               = local.domain
  validation_method         = "DNS"
  subject_alternative_names = ["www.${local.domain}"]

  lifecycle {
    create_before_destroy = true
  }
}
