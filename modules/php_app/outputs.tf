/*output "public_subnet_a_id" {
  value = data.aws_subnet.public_subnet_a.id
}
*/
output "aws_db_php" {
  value = aws_db_instance.PHP_app.id
}


output "aws_db_php_endpoint" {
  value = aws_db_instance.PHP_app.address
}


output "vpc_id" {
  value = aws_vpc.PHP_app.id
}

output "public_subnet_id_a" {
  value = aws_subnet.public_a.id
}

output "public_subnet_id_b" {
  value = aws_subnet.public_b.id
}

output "private_subnet_id_a" {
  value = aws_subnet.private_a.id
}

output "private_subnet_id_b" {
  value = aws_subnet.private_b.id
}

output "env_security_group" {
  value = aws_security_group.my_webserver.id
}
