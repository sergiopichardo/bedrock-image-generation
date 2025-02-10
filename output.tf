output "api_gateway_url" {
  description = "Image generation API Gateway URL"
  value       = "${aws_api_gateway_stage.image_generation_stage.invoke_url}/image_generation"
}
