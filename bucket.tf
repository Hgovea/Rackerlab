resource "aws_s3_bucket" "RP" {
  bucket = "rackerlife"

  tags = {
    Name        = "Rackerlife"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.RP.id
  acl    = "private"
}