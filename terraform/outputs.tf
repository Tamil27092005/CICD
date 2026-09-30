output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "app_url" {
  description = "URL of the deployed application"
  value       = "http://${aws_instance.app.public_ip}:${var.app_port}"
}
