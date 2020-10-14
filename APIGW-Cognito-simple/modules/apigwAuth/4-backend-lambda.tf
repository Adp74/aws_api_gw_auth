data "archive_file" "backend_lambda" {
  type = "zip"

  output_path = "${path.module}/code/backendLambda.zip"
  source {
    content  = file("${path.module}/code/backendLambda.py")
    filename = "backendLambda.py"
  }
}

resource "aws_lambda_function" "backend_lambda" {
  filename         = "${path.module}/code/backendLambda.zip"
  function_name    = var.backend_lambda_function_name
  role             = aws_iam_role.backend_lambda-iam-role.arn
  handler          = "backendLambda.handler"
  runtime          = var.backend_lambda_runtime
  source_code_hash = data.archive_file.backend_lambda.output_base64sha256
  timeout          = var.backend_lambda_timeout

  
  tags = merge(
    var.tags,
    {
      "Purpose" = "API GW Backend Lambda function for API GW"
      "Name"    = var.backend_lambda_function_name
    },
  )

}


resource "aws_iam_role" "backend_lambda-iam-role" {
  name = "${var.backend_lambda_function_name}-iam-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
POLICY


  tags = merge(
    var.tags,
    {
      "Name"    = "${var.backend_lambda_function_name}-iam-role"
    },
  )
}

# policy to let lambda access the ssm managed resources and logs
resource "aws_iam_role_policy" "backend_lambda-iam_inline_policy" {
  name = "backend_lambda-inline-policy-logs-ssm"
  role = aws_iam_role.backend_lambda-iam-role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSLambdaBasicExecutionRoleAccess",
      "Effect": "Allow",
      "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AccessvpcResources",
      "Effect": "Allow",
      "Action":  [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DescribeSSM",
      "Effect": "Allow",
      "Action": "ssm:DescribeParameters",
      "Resource": "*"
    }
  ]
}
EOF

}

