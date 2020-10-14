#-----------------------TAGS RELATED
variable "ENV" {
}

variable "tags" {
  type        = map(string)
  description = "REQUIRED - Tags to apply to the resources"
}

variable "PROJECT" {
  description = "Name of the project, used in a lot of the resource naming"
}

####--- API GW VARIABLES
variable "api_gw_name" {
  description = "name for AWS API GW"
  type        = "string"
}

variable "minimum_compression_size" {
  type        = number
  default     = -1
  description = "Minimum response size to compress for the REST API. Integer between -1 and 10485760 (10MB). Setting a value greater than -1 will enable compression, -1 disables compression (default)."
}

#When you associate a usage plan with an API and enable API keys on API methods, every incoming request to the API must contain an API key. 
#API Gateway reads the key and compares it against the keys in the usage plan. If there is a match, API Gateway throttles the requests according 
#to the plan's request limit and quota. Otherwise, it throws an InvalidKeyParameter exception. As a result, the caller receives a 403 Forbidden response.
variable "api_key_source" {
  type        = string
  default     = "HEADER"
  description = "The source of the API key for requests. Valid values are HEADER (default) and AUTHORIZER."
}

variable "api_gw_endpoint_type"{
    description = "type for API GW endpoint. One of EDGE, REGIONAL or PRIVATE"
    type = "string"
    default = "REGIONAL"
}

variable "api_gw_resource_path_part"{
    description = "path part for api gw resource"
    type = "string"
}

variable "api_gw_resource_method"{
    description = "path part for api gw resource method. One of GET, POST, PUT, DELETE, HEAD, OPTIONS or ANY"
    type = "string"   
}

#type of API GW authorizer. Possible values are TOKEN for a Lambda function using a single authorization token submitted in a custom header,
#REQUEST for a Lambda function using incoming request parameters, or COGNITO_USER_POOLS for using an Amazon Cognito user pool. 
variable "aws_api_gateway_authorizer_type"{
    description = "Type of API GW Authorizer. Possible values are TOKEN, REQUEST or COGNITO_USER_POOLS"
    type = "string"  
    default = "COGNITO_USER_POOLS"
}

variable "api_gw_method_authorization"{
    description = "path part for api gw resource method. One of NONE, CUSTOM, AWS_IAM or COGNITO_USER_POOLS"
    type = "string"  
    default = "COGNITO_USER_POOLS"
}

# variable "authorization_scopes"{
#     description = "The authorization scopes used when the authorization is COGNITO_USER_POOLS"
#     type = list 
#     default = []
# }

variable "stage_name"{
    description = "Stage name for API GW"
    type = "string"  
}

variable "api_gw_logs_enable"{
    description = "Boolean variable to enable or disable logs for api gw"
    type = bool 
    default = false
}

variable "api_gw_logging_level"{
    description = "Specifies the logging level for this method, which effects the log entries pushed to Amazon CloudWatch Logs. The available levels are OFF, ERROR, and INFO"
    type = "string"
    default = "INFO"
}


variable "api_gw_xray_tracing_enabled"{
    description = "Specifies whether active tracing with X-ray is enabled for API GW stage"
    type = bool
    default = false
}



variable "api_gw_variables_stage"{
    description = "Specifies a map that defines the stage variables"
    type = map
    default = {}
}

variable "api_gw_custom_domain_enabled"{
    description = "Specifies whether custom domain is created or not for api gw"
    type = bool
    default = false
}

variable "api_gw_custom_domain_name"{
    description = "name for the custom domain of API GW"
    type = "string"
    default = ""
}

variable "api_gw_custom_domain_zone_id"{
    description = "route 53 zone id for creating route 53 record of domain name of API GW"
    type = "string"
    default = ""
}


variable "api_gw_custom_base_path"{
    description = "base path for api gw custom domain mappings"
    type = "string"
    default = ""
}


####--- BACKEND LAMBDA VARIABLES

variable "backend_lambda_function_name"{
    description = "name for backend lambda function"
    type = "string"
}
variable "backend_lambda_runtime"{
    description = "runtime for backend lambda function"
    type = "string"
    default = "python3.7"
}

variable "backend_lambda_timeout"{
    description = "runtime for backend lambda function"
    type = number
    default = 900
}

#----- cognito
variable "cognito_user_pool_enabled"{
    description = "Specified whether cognito user pool is enabled or not"
    type = bool
    default = true
}

variable "cognito_user_pool_name"{
    description = "cognito user pool name"
    type = "string"
    default = ""
}

variable "cognito_user_pool_client_name"{
    description = "cognito user pool client name"
    type = "string"
    default = ""
}


variable "cognito_user_pool_scope_name"{
    description = "cognito user pool scope name"
    type = "string"
    default = "accesstoken"
}


variable "cognito_user_pool_scope_description"{
    description = "cognito user pool scope description"
    type = "string"
    default = ""
}

variable "cognito_user_pool_custom_domain_enabled"{
    description = "Specifies whether cognito user pool custom domain is created or not"
    type = bool
    default = false
}

variable "cognito_user_pool_custom_domain_name"{
    description = "cognito user pool custom domain name"
    type = "string"
    default = ""
}

variable "cognito_user_pool_route_53_zone_id"{
    description = "route53 zone id where cognito user pool custom domain dns record will be added"
    type = "string"
    default = ""
}

#### lambda authorizer
variable "lambda_authorizer_timeout"{
    description = "runtime for lambda authorizer function"
    type = number
    default = 900
}

variable "lambda_authorizer_runtime"{
    description = "runtime for lambda authorizer function"
    type = "string"
    default = "python3.7"
}