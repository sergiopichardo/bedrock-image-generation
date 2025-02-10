resource "random_bytes" "random_suffix" {
  length = 8
}

resource "aws_s3_bucket" "image_generation_bucket" {
  bucket        = "${local.project_name}-bucket-${random_bytes.random_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "${local.project_name}-bucket-${random_bytes.random_suffix.hex}"
    Environment = "Dev"
    Author      = "${local.author}"
  }
}
