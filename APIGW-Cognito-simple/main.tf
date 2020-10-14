module "api-gateway" {
  source = "./modules/apigwAuth"
  
  #TAGS
  ENV = var.ENV
  tags = local.common_tags
  PROJECT = var.PROJECT
  
  #providers
  providers = {
    aws.us-east-1 = aws.use1
  }
  
  #Rest API config
  api_gw_name = "poc-apigw-auth"
  minimum_compression_size = 10000000
  api_gw_endpoint_type = "REGIONAL"
  
  # Api Gateway Resource and method
  api_gw_resource_path_part = "cognito"
  api_gw_resource_method = "POST"
  
  # Api GW authorizer
  aws_api_gateway_authorizer_type = "COGNITO_USER_POOLS"
  
  #Api GW method authorization
  api_gw_method_authorization = "COGNITO_USER_POOLS"


  # Api Gateway Stage and Deployment
  stage_name         = "dev"
  api_gw_logs_enable = true
  

  # Api Gateway Custom Domain
  api_gw_custom_domain_enabled = true
  api_gw_custom_domain_name = "apigwauth.env.subdomain.example.com"
  api_gw_custom_domain_zone_id = "Z07385573QBI7FBVW1GFD"
  api_gw_custom_base_path = "dev"

  #backend lambda
  backend_lambda_function_name = "apigw-auth-backend"
  
  #cognito
  cognito_user_pool_enabled = true
  cognito_user_pool_name = "poc-apigw-auth"
  cognito_user_pool_client_name = "poc"
  cognito_user_pool_scope_name = "accesstoken"
  cognito_user_pool_scope_description = "scope for api gw"
  cognito_user_pool_custom_domain_enabled = true
  cognito_user_pool_custom_domain_name = "auth.cognito-poc.env.subdomain.example.com"
  cognito_user_pool_route_53_zone_id = "Z07385573QBI7FBVW1GFD"
}