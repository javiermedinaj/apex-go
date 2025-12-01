output "instance_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.forgeai.id
}

output "public_ip" {
  description = "IP pública de la instancia"
  value       = aws_eip.forgeai.public_ip
}

output "public_dns" {
  description = "DNS público de la instancia"
  value       = aws_eip.forgeai.public_dns
}

output "website_url" {
  description = "URL del sitio web"
  value       = "http://${aws_eip.forgeai.public_ip}"
}

output "ssh_command" {
  description = "Comando para conectar por SSH"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_eip.forgeai.public_ip}"
}
