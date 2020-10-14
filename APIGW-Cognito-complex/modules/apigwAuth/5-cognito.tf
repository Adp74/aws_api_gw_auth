locals{
  callback_url = "https://${var.api_gw_custom_domain_name}"
 // Copy domain_validation_options for the distinct domain names
  cognito_validation_domains = (var.cognito_user_pool_enabled == true && var.cognito_user_pool_custom_domain_enabled == true) ? [for k, v in aws_acm_certificate.cognito_certificate[0].domain_validation_options : tomap(v)] : []

}

resource "aws_cognito_user_pool" "pool" {
  depends_on = [aws_api_gateway_rest_api.apigw]
  count = var.cognito_user_pool_enabled == true ? 1 : 0
  name                       = var.cognito_user_pool_name
  alias_attributes        = ["preferred_username"]

  admin_create_user_config {
    allow_admin_create_user_only = false
  }
  
  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }
  # tags
  tags = var.tags
}

resource "aws_cognito_user_pool_domain" "main" {
  count = var.cognito_user_pool_enabled == true ? 1 : 0
  domain       = var.api_gw_name
  user_pool_id = aws_cognito_user_pool.pool[0].id
}


# aws_cognito_user_pool_client._
resource "aws_cognito_user_pool_client" "client" {
  depends_on = [aws_api_gateway_rest_api.apigw]
  count = var.cognito_user_pool_enabled == true ? 1 : 0
  name = var.cognito_user_pool_client_name
  allowed_oauth_flows_user_pool_client = true
  supported_identity_providers = ["COGNITO"]
  user_pool_id    = aws_cognito_user_pool.pool[0].id
  generate_secret = true
  allowed_oauth_flows = ["client_credentials"]
  allowed_oauth_scopes = aws_cognito_resource_server.scope[0].scope_identifiers
  callback_urls = [local.callback_url]
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

resource "aws_cognito_resource_server" "scope" {
  depends_on = [aws_api_gateway_rest_api.apigw]
  count = var.cognito_user_pool_enabled == true ? 1 : 0
  identifier = local.callback_url
  name       = var.api_gw_name
  user_pool_id = aws_cognito_user_pool.pool[0].id
  
  scope {
    scope_name        = var.cognito_user_pool_scope_name
    scope_description = var.cognito_user_pool_scope_description
  }
}


####custom domain
resource "aws_cognito_user_pool_domain" "cognito_custom_domain" {
  depends_on = [aws_api_gateway_rest_api.apigw]
  count = (var.cognito_user_pool_enabled == true && var.cognito_user_pool_custom_domain_enabled) == true ? 1 : 0
  domain          = var.cognito_user_pool_custom_domain_name
  certificate_arn = aws_acm_certificate.cognito_certificate[0].arn
  user_pool_id    = aws_cognito_user_pool.pool[0].id
}


resource "aws_route53_record" "cognito_custom_domain_record" {
  count = var.cognito_user_pool_enabled == true && var.cognito_user_pool_custom_domain_enabled == true ? 1 : 0
  name    = aws_cognito_user_pool_domain.cognito_custom_domain[0].domain
  type    = "A"
  zone_id = var.cognito_user_pool_route_53_zone_id
  alias {
    evaluate_target_health = false
    name                   = aws_cognito_user_pool_domain.cognito_custom_domain[0].cloudfront_distribution_arn
    # This zone_id is fixed
    zone_id = "Z2FDTNDATAQYW2"
  }
}


#ACM certificate
resource "aws_acm_certificate" "cognito_certificate" {
  provider = "aws.us-east-1"
  count = var.cognito_user_pool_enabled == true && var.cognito_user_pool_custom_domain_enabled == true ? 1 : 0
  domain_name       = var.cognito_user_pool_custom_domain_name
  validation_method = "DNS"

  tags = merge(
    var.tags,
    {
      "Purpose" = "ACM for cognito user pool"
      "Name"    = "${var.cognito_user_pool_name}-cognito-certificate"
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}
 

resource "aws_route53_record" "cognito_certificate_validation" {
  count = var.cognito_user_pool_enabled == true && var.cognito_user_pool_custom_domain_enabled == true ? 1 : 0
  depends_on = [aws_acm_certificate.cognito_certificate]
  # for_each = {
  #   for dvo in aws_acm_certificate.cognito_certificate[0].domain_validation_options : dvo.domain_name => {
  #     name   = dvo.resource_record_name
  #     record = dvo.resource_record_value
  #     type   = dvo.resource_record_type
  #   }
  # }

  allow_overwrite = true
  name            = element(local.cognito_validation_domains, count.index)["resource_record_name"]
  records         = [
    element(local.cognito_validation_domains, count.index)["resource_record_value"]
  ]
  ttl             = 60
  type            = element(local.cognito_validation_domains, count.index)["resource_record_type"]
  zone_id         = var.cognito_user_pool_route_53_zone_id
  
}

resource "aws_acm_certificate_validation" "cognito_certificate" {
  count = var.cognito_user_pool_enabled == true && var.cognito_user_pool_custom_domain_enabled == true ? 1 : 0
  depends_on = [aws_acm_certificate.cognito_certificate]
  certificate_arn         = aws_acm_certificate.cognito_certificate[0].arn
  validation_record_fqdns  = aws_route53_record.cognito_certificate_validation.*.fqdn
}