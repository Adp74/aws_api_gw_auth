locals{
  #aws_api_gateway_authorizer
  authorizer_uri = var.aws_api_gateway_authorizer_type == "COGNITO_USER_POOLS" ? null : aws_lambda_function.authorizer[0].invoke_arn
  authorizer_credentials = var.aws_api_gateway_authorizer_type == "COGNITO_USER_POOLS" ? null : aws_iam_role.invocation_role[0].arn
  provider_arns = var.aws_api_gateway_authorizer_type == "COGNITO_USER_POOLS" ? [aws_cognito_user_pool.pool[0].arn] : null
  #aws_api_gateway_method
  authorizer_id = (var.api_gw_method_authorization == "COGNITO_USER_POOLS" || var.api_gw_method_authorization == "CUSTOM") ? aws_api_gateway_authorizer.api_gw_authorizer.id : null
  authorization_scopes = var.api_gw_method_authorization == "COGNITO_USER_POOLS" ? ["https://${var.api_gw_custom_domain_name}/${var.cognito_user_pool_scope_name}",] : null

  // Copy domain_validation_options for the distinct domain names
  validation_domains = var.api_gw_custom_domain_enabled ? [for k, v in aws_acm_certificate.apigw_certificate[0].domain_validation_options : tomap(v)] : []

  #resources and methods
  #total_methods = {for k,v in var.api_gw_resources_and_methods : for each method in var.api_gw_resources_and_methods[k]["methods"] : join(",",[k,method])={"resource"=k,"method"=method}}
  
  method_list = flatten([
    for k in keys(var.api_gw_resources_and_methods) : [
      for method in var.api_gw_resources_and_methods[k]["methods"] : {
        key   = k
        method = method
      }
    ]
  ])
}

###########################################################
## API Gateway Set Up
###########################################################
resource "aws_api_gateway_rest_api" "apigw" {
  name                     =var.api_gw_name
  description              = "API GW with Cognito User Pool authorization"
  minimum_compression_size = var.minimum_compression_size
  api_key_source           = var.api_key_source
  
  endpoint_configuration {
    types = [var.api_gw_endpoint_type]
  }

}

######-----API GW RESOURCE AND METHODS--------------------------------------------

resource "aws_api_gateway_resource" "api_gw_resource_for_each" {
  for_each = var.api_gw_resources_and_methods
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  parent_id   = aws_api_gateway_rest_api.apigw.root_resource_id
  path_part   = each.value["path"]
}

# resource "aws_api_gateway_resource" "api_gw_resource" {
#   rest_api_id = aws_api_gateway_rest_api.apigw.id
#   parent_id   = aws_api_gateway_rest_api.apigw.root_resource_id
#   path_part   = var.api_gw_resource_path_part
# }
#possible values for type of gateway authroizer are: TOKEN for lambda function using a single authorization token, 
#REQUEST for lamda function using incoming request parameters or COGNITO_USER_POOLS
  
resource "aws_api_gateway_authorizer" "api_gw_authorizer" {
  name          = "APIGWAuthorizer"
  authorizer_uri = local.authorizer_uri
  authorizer_credentials = local.authorizer_credentials
  type          = var.aws_api_gateway_authorizer_type
  rest_api_id   = aws_api_gateway_rest_api.apigw.id
  provider_arns = local.provider_arns
}

resource "aws_api_gateway_method" "api_gw_method_for_each" {
  depends_on = [aws_api_gateway_authorizer.api_gw_authorizer]
  count      = length(local.method_list)
  rest_api_id   = aws_api_gateway_rest_api.apigw.id
  resource_id   = aws_api_gateway_resource.api_gw_resource_for_each[local.method_list[count.index].key].id
  http_method   = local.method_list[count.index].method
  authorization = var.api_gw_method_authorization
  authorizer_id = local.authorizer_id
  authorization_scopes = local.authorization_scopes
}

# resource "aws_api_gateway_method" "api_gw_method" {
#   depends_on = [aws_api_gateway_authorizer.api_gw_authorizer]
#   rest_api_id   = aws_api_gateway_rest_api.apigw.id
#   resource_id   = aws_api_gateway_resource.api_gw_resource.id
#   http_method   = var.api_gw_resource_method
#   authorization = var.api_gw_method_authorization
#   authorizer_id = local.authorizer_id
#   authorization_scopes = local.authorization_scopes
# }


resource "aws_api_gateway_integration" "api_gw_for_each" {
  count      = length(local.method_list)
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_method.api_gw_method_for_each[count.index].resource_id
  http_method = aws_api_gateway_method.api_gw_method_for_each[count.index].http_method

  # The integration HTTP method specifying how API Gateway 
  # will interact with the back end. Not all methods are 
  # compatible with all AWS integrations. e.g. 
  # Lambda function can only be invoked via POST.
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.backend_lambda.invoke_arn
}

# resource "aws_api_gateway_integration" "api_gw" {
#   rest_api_id = aws_api_gateway_rest_api.apigw.id
#   resource_id = aws_api_gateway_method.api_gw_method.resource_id
#   http_method = aws_api_gateway_method.api_gw_method.http_method

#   # The integration HTTP method specifying how API Gateway 
#   # will interact with the back end. Not all methods are 
#   # compatible with all AWS integrations. e.g. 
#   # Lambda function can only be invoked via POST.
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.backend_lambda.invoke_arn
# }


######DEPLOYMENT AND PERMISSIONS
resource "aws_api_gateway_deployment" "apigw_deployment" {
  depends_on  = [aws_api_gateway_integration.api_gw_for_each]
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  stage_name  = var.stage_name
}

# resource "aws_lambda_permission" "apigw-api_gwbackend-permissions" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.backend_lambda.function_name
#   principal     = "apigateway.amazonaws.com"

#   # The /*/* portion grants access from any method on any resource
#   # within the API Gateway "REST API".
#   source_arn = "${aws_api_gateway_rest_api.apigw.execution_arn}/*/POST/${var.api_gw_resource_path_part}"

# }

resource "aws_lambda_permission" "apigw-api_gwbackend-permissions_for_each" {
  for_each      = var.api_gw_resources_and_methods
  statement_id  = "AllowAPIGatewayInvoke-${each.value["path"]}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.apigw.execution_arn}/*/*/${each.value["path"]}"

}


###########################################################
## Enabling API Gateway logs via CloudWatchLogs
###########################################################
resource "aws_api_gateway_account" "apigw" {
  count = var.api_gw_logs_enable == true ? 1 : 0
  cloudwatch_role_arn = aws_iam_role.apigw-logs[0].arn
}

resource "aws_iam_role" "apigw-logs" {
  count = var.api_gw_logs_enable == true ? 1 : 0
  name  = "${var.PROJECT}-${var.api_gw_name}-api-gw-logs"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
    {
      "Sid"       : "",
      "Effect"    : "Allow",
      "Principal" : {
        "Service"   : "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "cloudwatch" {
  count = var.api_gw_logs_enable == true ? 1 : 0
  name = "${var.PROJECT}-api-gw-cloudwatch-policy"
  role = aws_iam_role.apigw-logs[0].id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_api_gateway_method_settings" "apigw_method_settings" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  stage_name  = var.stage_name

  #method_path = "${aws_api_gateway_resource.api_gw.path_part}/${aws_api_gateway_method.api_gw.http_method}"
  ## Currently there is a open bug with this resource which is that the mehtod settings are 
  ## not updated properly. An workaround is to set the method_path to "*/*".
  ## For more info: https://github.com/terraform-providers/terraform-provider-aws/issues/1550
  method_path = "*/*"

  settings {
    metrics_enabled    = var.api_gw_logs_enable
    logging_level      = var.api_gw_logging_level
    data_trace_enabled = var.api_gw_logs_enable
  }

}

# resource "aws_api_gateway_stage" "apigw_stage" {
#   stage_name    = "prod"
#   rest_api_id   = aws_api_gateway_rest_api.apigw.id
#   deployment_id = aws_api_gateway_deployment.apigw_deployment.id
#   xray_tracing_enabled  = var.api_gw_xray_tracing_enabled
#   variables = var.api_gw_variables_stage
# }

###########################################################
## Custom Domain Set up
###########################################################

##API Gateway domains can be defined as either 'edge-optimized' or 'regional'. In an edge-optimized configuration, 
##API Gateway internally creates and manages a CloudFront distribution to route requests on the given hostname. 
##In addition to this resource it's necessary to create a DNS record corresponding to the given domain name which is an alias (either Route53 alias or traditional CNAME) 
##to the Cloudfront domain name exported in the cloudfront_domain_name attribute.
resource "aws_api_gateway_domain_name" "apigw_domain_name" {
  depends_on = [aws_api_gateway_rest_api.apigw, aws_acm_certificate_validation.apigw_certificate_validation]
  count      = var.api_gw_custom_domain_enabled == true ? 1 : 0 
  domain_name              = var.api_gw_custom_domain_name
  regional_certificate_arn = aws_acm_certificate_validation.apigw_certificate_validation[0].certificate_arn

  endpoint_configuration {
    types = [var.api_gw_endpoint_type]
  }
}

##IF REGIONAL
resource "aws_route53_record" "apigw_route53_domain_name" {
  count      = var.api_gw_custom_domain_enabled == true ? 1 : 0 
  zone_id = var.api_gw_custom_domain_zone_id
  name    = aws_api_gateway_domain_name.apigw_domain_name[0].domain_name
  type    = "A"

  alias {
    name                   = var.api_gw_endpoint_type == "REGIONAL" ? aws_api_gateway_domain_name.apigw_domain_name[0].regional_domain_name : aws_api_gateway_domain_name.apigw_domain_name[0].cloudfront_domain_name
    zone_id                = var.api_gw_endpoint_type == "REGIONAL" ? aws_api_gateway_domain_name.apigw_domain_name[0].regional_zone_id : aws_api_gateway_domain_name.apigw_domain_name[0].cloudfront_zone_id 
    evaluate_target_health = true
  }
}

####Connects a custom domain name registered via aws_api_gateway_domain_name with a deployed API 
####so that its methods can be called via the custom domain name.
resource "aws_api_gateway_base_path_mapping" "apigw_path_mapping" {
  count      = var.api_gw_custom_domain_enabled == true ? 1 : 0 
  depends_on = [aws_api_gateway_deployment.apigw_deployment]
  api_id      = aws_api_gateway_rest_api.apigw.id
  domain_name = aws_api_gateway_domain_name.apigw_domain_name[0].domain_name
  stage_name  = var.stage_name
  base_path   = var.api_gw_custom_base_path
}


#ACM certificate
resource "aws_acm_certificate" "apigw_certificate" {
  count      = var.api_gw_custom_domain_enabled == true ? 1 : 0 
  domain_name       = var.api_gw_custom_domain_name
  validation_method = "DNS"

  tags = merge(
    var.tags,
    {
      "Purpose" = "ACM for ${var.api_gw_name} API GW"
      "Name"    = "${var.PROJECT}-${var.api_gw_name}-api-gw"
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}
 

resource "aws_route53_record" "apigw_validation" {
  depends_on = [aws_acm_certificate.apigw_certificate]
  count      = var.api_gw_custom_domain_enabled == true ? 1 : 0 
  # for_each = {
  #   for dvo in aws_acm_certificate.apigw_certificate[0].domain_validation_options : dvo.domain_name => {
  #     name   = dvo.resource_record_name
  #     record = dvo.resource_record_value
  #     type   = dvo.resource_record_type
  #   }
  # }

  allow_overwrite = true
  name            = element(local.validation_domains, count.index)["resource_record_name"]
  records         = [
    element(local.validation_domains, count.index)["resource_record_value"]
  ]
  ttl             = 60
  type            = element(local.validation_domains, count.index)["resource_record_type"]
  zone_id         = var.api_gw_custom_domain_zone_id
  
}

resource "aws_acm_certificate_validation" "apigw_certificate_validation" {
  depends_on = [aws_acm_certificate.apigw_certificate]
  count      = var.api_gw_custom_domain_enabled == true ? 1 : 0 
  certificate_arn         = aws_acm_certificate.apigw_certificate[0].arn
  validation_record_fqdns  = aws_route53_record.apigw_validation.*.fqdn
}