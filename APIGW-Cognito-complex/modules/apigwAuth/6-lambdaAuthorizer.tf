data "archive_file" "lambda_authorizer" {
  count = var.api_gw_method_authorization == "COGNITO_USER_POOLS" ? 0 : 1
  type = "zip"

  output_path = "${path.module}/code/lambdaAuthorizer.zip"
  source {
    content  = file("${path.module}/code/lambdaAuthorizer.py")
    filename = "lambdaAuthorizer.py"
  }
}

resource "aws_lambda_function" "authorizer" {
  count = var.api_gw_method_authorization == "COGNITO_USER_POOLS" ? 0 : 1
  filename      = "${path.module}/code/lambdaAuthorizer.zip"
  function_name = "${var.api_gw_name}-api-gateway-authorizer"
  role          = aws_iam_role.lambda[0].arn
  handler       = "lambdaAuthorizer.lambda_handler"
  timeout       = var.lambda_authorizer_timeout
  runtime       = var.lambda_authorizer_runtime
  source_code_hash = data.archive_file.lambda_authorizer[0].output_base64sha256
  
  tags = merge(
    var.tags,
    {
      "Purpose" = "API GW Lambda authorizer function"
      "Name"    = "${var.api_gw_name}-api-gateway-authorizer"
    },
  )
}

resource "aws_iam_role" "invocation_role" {
  count = var.api_gw_method_authorization == "COGNITO_USER_POOLS" ? 0 : 1
  name = "api_gateway_auth_invocation"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "invocation_policy" {
  count = var.api_gw_method_authorization == "COGNITO_USER_POOLS" ? 0 : 1
  name = "default"
  role = aws_iam_role.invocation_role[0].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.authorizer[0].arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda" {
  count = var.api_gw_method_authorization == "COGNITO_USER_POOLS" ? 0 : 1
  name = "demo-lambda"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

