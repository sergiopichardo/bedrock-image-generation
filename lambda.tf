data "archive_file" "image_generation" {
  type        = "zip"
  source_file = "${path.root}/lambda_functions/image_generation/index.py"
  output_path = "${path.root}/lambda_functions/image_generation/image_generation_lambda_function.zip"
}

output "image_generation_lambda_function_zip" {
  value = data.archive_file.image_generation.output_path
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
      }
    ]
  })
}

resource "aws_iam_policy" "basic_lambda_permissions" {
  name        = "basic_lambda_permissions"
  description = "Basic lambda permissions"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.image_generation_bucket.arn,
          "${aws_s3_bucket.image_generation_bucket.arn}/*"
        ]
      },
      {
        Action = [
          "bedrock:InvokeModel",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "basic_lambda_permissions_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.basic_lambda_permissions.arn
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "image_generation" {
  filename         = data.archive_file.image_generation.output_path
  function_name    = "${local.project_name}-lambda-function"
  handler          = "index.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda_role.arn
  timeout          = 180 # Increase timeout to 3 minutes since image generation might take longer
  source_code_hash = filebase64sha256("${path.root}/lambda_functions/image_generation/image_generation_lambda_function.zip")
  memory_size      = 1024 # Add more memory if needed

  environment {
    variables = {
      BUCKET_NAME      = aws_s3_bucket.image_generation_bucket.bucket,
      BEDROCK_MODEL_ID = "stability.stable-diffusion-xl-v1"
    }
  }

  tags = {
    Name = "${local.project_name}-lambda-function"
  }
}
