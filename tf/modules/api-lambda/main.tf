locals {
    image_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.image_repo_name}:${var.image_tag}"
}

resource "aws_lambda_function" "epoch" {
    function_name = var.function_name
    role          = aws_iam_role.lambda_exec.arn
    package_type  = "Image"
    image_uri     = local.image_uri
    timeout       = 3

    image_config {
        command = [var.function_handler]
    }

    environment {
        variables = {
            IMAGE_TAG = var.image_tag
      }
    }
}

resource "aws_iam_role" "lambda_exec" {
    name = "${var.function_name}-lambda-exec"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
        Action    = "sts:AssumeRole",
        Principal = { Service = "lambda.amazonaws.com" },
        Effect    = "Allow",
        }]
    })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_apigatewayv2_api" "api" {
    name          = var.api_name
    protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
    api_id           = aws_apigatewayv2_api.api.id
    integration_type = "AWS_PROXY"
    integration_uri  = aws_lambda_function.epoch.invoke_arn
    integration_method = "POST"
    payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
    api_id    = aws_apigatewayv2_api.api.id
    route_key = "GET /"
    target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
    api_id      = aws_apigatewayv2_api.api.id
    name        = "$default"
    auto_deploy = true
}

resource "aws_lambda_permission" "api" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.epoch.arn
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

output "invoke_url" {
    value = aws_apigatewayv2_api.api.api_endpoint
}
