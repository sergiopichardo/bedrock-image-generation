# Creates the main REST API Gateway for image generation
resource "aws_api_gateway_rest_api" "image_generation_api" {
  name        = "image-generation-api"
  description = "API for image generation"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Creates the API resource/endpoint path for image generation
resource "aws_api_gateway_resource" "image_generation_resource" {
  rest_api_id = aws_api_gateway_rest_api.image_generation_api.id
  parent_id   = aws_api_gateway_rest_api.image_generation_api.root_resource_id
  path_part   = "image_generation"
}

# Defines the POST method for the image generation endpoint
resource "aws_api_gateway_method" "create_image_method" {
  rest_api_id   = aws_api_gateway_rest_api.image_generation_api.id
  resource_id   = aws_api_gateway_resource.image_generation_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integrates the API endpoint with the Lambda function
resource "aws_api_gateway_integration" "create_image_integration" {
  rest_api_id             = aws_api_gateway_rest_api.image_generation_api.id
  resource_id             = aws_api_gateway_resource.image_generation_resource.id
  http_method             = aws_api_gateway_method.create_image_method.http_method
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.image_generation.invoke_arn
  integration_http_method = "POST"
}

# Grants API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "create_image_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_generation.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.image_generation_api.execution_arn}/*/*"
}

# Defines the successful (200) response for the API method
resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.image_generation_api.id
  resource_id = aws_api_gateway_resource.image_generation_resource.id
  http_method = aws_api_gateway_method.create_image_method.http_method
  status_code = "200"
}

# Configures the response integration with a success message
resource "aws_api_gateway_integration_response" "create_image_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.image_generation_api.id
  resource_id = aws_api_gateway_resource.image_generation_resource.id
  http_method = aws_api_gateway_method.create_image_method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  depends_on = [aws_api_gateway_integration.create_image_integration]

  response_templates = {
    "application/json" = "{\"message\": \"Image created successfully\"}"
  }
}

# Creates a deployment for the API changes
# The triggers block ensures the API is redeployed when the resource, method, or integration changes
# by creating a hash of their configurations. The depends_on ensures methods exist before deployment.
resource "aws_api_gateway_deployment" "image_generation_deployment" {
  rest_api_id = aws_api_gateway_rest_api.image_generation_api.id

  triggers = {
    redeployment = sha1(join(",", [
      jsonencode(aws_api_gateway_resource.image_generation_resource),
      jsonencode(aws_api_gateway_method.create_image_method),
      jsonencode(aws_api_gateway_integration.create_image_integration)
    ]))
  }

  depends_on = [
    aws_api_gateway_method.create_image_method,
    aws_api_gateway_integration.create_image_integration
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Creates a development stage for the API deployment
resource "aws_api_gateway_stage" "image_generation_stage" {
  deployment_id = aws_api_gateway_deployment.image_generation_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.image_generation_api.id
  stage_name    = var.environment
}

