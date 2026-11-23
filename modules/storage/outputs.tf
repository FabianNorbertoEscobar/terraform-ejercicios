output "bucket_name" {
  description = "Nombre del bucket."
  value       = aws_s3_bucket.this.id
}
