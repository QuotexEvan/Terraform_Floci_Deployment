terraform {
  required_version = ">= 1.0.0"


  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  s3_use_path_style = true
  endpoints {
    iam          = "http://localhost:4566"
    lambda       = "http://localhost:4566"
    s3           = "http://localhost:4566"
    apigatewayv2 = "http://localhost:4566"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_lambda_function" "app" {
  function_name = "deploy-app"
  filename      = "${path.module}/../build/lambda.zip"
  source_code_hash = filebase64sha256(
    "${path.module}/../build/lambda.zip"
  )

  role = aws_iam_role.lambda_role.arn

  runtime = "python3.13"
  handler = "handler.handler"

  memory_size = 128
  timeout     = 10
}

resource "aws_apigatewayv2_api" "api" {
  name          = "deploy-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.app.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.app.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_s3_bucket" "releases" {
  bucket        = "deploy-releases"
  force_destroy = true
}

output "lambda_name" {
  value = aws_lambda_function.app.function_name
}

output "api_id" {
  value = aws_apigatewayv2_api.api.id
}

output "health_url" {
  value = "http://${aws_apigatewayv2_api.api.id}.execute-api.localhost.floci.io:4566/health"
}

output "release_bucket" {
  value = aws_s3_bucket.releases.bucket
}