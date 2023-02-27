resource "aws_acm_certificate" "pufferfish" {
  domain_name               = var.domain
  validation_method         = "DNS"
  subject_alternative_names = ["www.${var.domain}"]

  lifecycle {
    create_before_destroy = true
  }
}
