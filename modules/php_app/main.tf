resource "aws_vpc" "PHP_app" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "${var.env}-vpc"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.PHP_app.id
  cidr_block        = var.public_subnet_a_cidr_block
  availability_zone = "us-east-2a"

  tags = {
    Name = "${var.env}_public_a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.PHP_app.id
  cidr_block        = var.public_subnet_b_cidr_block
  availability_zone = "us-east-2b"

  tags = {
    Name = "${var.env}_public_b"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.PHP_app.id
  cidr_block        = var.private_subnet_a_cidr_block
  availability_zone = "us-east-2a"


  tags = {
    Name = "${var.env}_private_a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.PHP_app.id
  cidr_block        = var.private_subnet_b_cidr_block
  availability_zone = "us-east-2b"

  tags = {
    Name = "${var.env}_private_b"
  }
}

resource "aws_route_table" "PHP_app_public_a" {
  vpc_id = aws_vpc.PHP_app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.PHP_app.id
  }

  tags = {
    Name = "${var.env}_public"
  }
}

resource "aws_route_table" "PHP_app_private_a" {
  vpc_id = aws_vpc.PHP_app.id

  tags = {
    Name = "${var.env}_private"
  }
}

resource "aws_route_table_association" "PHP_app_public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.PHP_app_public_a.id
}

resource "aws_route_table_association" "PHP_app_private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.PHP_app_private_a.id
}

resource "aws_route_table_association" "PHP_app_public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.PHP_app_public_a.id
}

resource "aws_route_table_association" "PHP_app_private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.PHP_app_private_a.id
}

resource "aws_security_group" "my_webserver" {
  name        = "${var.env}_PHP_app"
  description = "${var.env}_PHP_app"
  vpc_id      = aws_vpc.PHP_app.id
  tags = {
    Name = "${var.env}_PHP_app"
  }
  #tags        = merge(var.common_tags, { Name = "${var.common_tags["Project"]} Server IP" })

  dynamic "ingress" {
    for_each = var.allow_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["77.87.158.69/32"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_internet_gateway" "PHP_app" {
  vpc_id = aws_vpc.PHP_app.id

  tags = {
    Name = "${var.env}_php_app"
  }
}

resource "aws_db_subnet_group" "database-subnet-group" {
  name        = "${var.env}.php_app_vpc"
  subnet_ids  = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  description = "Subnets for Database Instance"

  tags = {
    Name = "Database Subnets"
  }
}

resource "aws_db_instance" "PHP_app" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "8.0.27"
  instance_class         = "db.t2.micro"
  identifier             = "${var.env}-php-app"
  port                   = "3306"
  username               = var.user
  password               = var.password
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.database-subnet-group.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  db_name                = "php_mysql_crud"

}

resource "aws_security_group" "rds" {
  name        = "${var.env}_rds_sg"
  description = "${var.env}_rds_sg"
  vpc_id      = aws_vpc.PHP_app.id
  tags = {
    Name = "${var.env}_RDS"
  }
  #tags        = merge(var.common_tags, { Name = "${var.common_tags["Project"]} Server IP" })

  ingress {
    description = "RDS from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

data "aws_ami" "amazon_linux_2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.my_webserver.id]
  subnet_id                   = aws_subnet.public_a.id
  iam_instance_profile        = "s3-full"
  key_name                    = aws_key_pair.prod.key_name
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2 -y",
      "sudo yum install -y httpd mariadb-server",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
      "sudo aws s3 sync s3://php-app-epam/php-mysql-crud-master /var/www/html/",
      "mysql -u root -h ${aws_db_instance.PHP_app.address} --password=5526c03ba6  -e 'use php_mysql_crud; CREATE TABLE task(id int(11) NOT NULL, title varchar(255) COLLATE utf8_unicode_ci NOT NULL, description text COLLATE utf8_unicode_ci NOT NULL, created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;'",
      "sudo sed -i 's/php-app/${var.env}-php-app/g' /var/www/html/db.php"
    ]
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${path.module}/id_rsa")
    host        = self.public_ip
  }

  tags = {
    Name = "${var.env}_bastion"
  }

  depends_on = [aws_db_instance.PHP_app]
}

resource "aws_key_pair" "prod" {
  key_name   = "${var.env}-prod-key"
  public_key = file("${path.module}/id_rsa.pub")
}


resource "aws_ami_from_instance" "php_app" {
  name               = "${var.env}-php-app-image"
  source_instance_id = aws_instance.bastion.id
  depends_on         = [aws_instance.bastion]
}

resource "aws_lb" "php_app" {
  name               = "${var.env}-php-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_webserver.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.env}_PHP_LB"
  }

  depends_on = [aws_instance.bastion]
}

resource "aws_launch_configuration" "php_app" {
  name                 = "${var.env}_php_app"
  image_id             = aws_ami_from_instance.php_app.id
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.my_webserver.id]
  iam_instance_profile = "s3-full"
  key_name             = "${var.env}-prod-key"

  depends_on = [aws_instance.bastion]
}

resource "aws_autoscaling_group" "php_app" {
  name                      = "${var.env}_php_app"
  max_size                  = 3
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 2
  force_delete              = true
  #placement_group           = aws_placement_group.test.id
  launch_configuration = aws_launch_configuration.php_app.name
  vpc_zone_identifier  = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  depends_on           = [aws_instance.bastion]
  lifecycle {
    ignore_changes = ["target_group_arns"]
  }

}

resource "aws_lb_target_group" "php_app" {
  name       = "${var.env}-php-app-lb-tg"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = aws_vpc.PHP_app.id
  depends_on = [aws_instance.bastion]
}
resource "aws_autoscaling_attachment" "php_app" {
  autoscaling_group_name = aws_autoscaling_group.php_app.id
  lb_target_group_arn    = aws_lb_target_group.php_app.arn
  depends_on             = [aws_instance.bastion]
}

resource "aws_lb_listener" "php_app_tg" {
  load_balancer_arn = aws_lb.php_app.arn
  port              = "443"
  protocol          = "HTTPS"
  depends_on        = [aws_instance.bastion]
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-2:990032074338:certificate/332fe32a-1a0a-4b8e-ad08-54a6ba710712"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.php_app.arn
  }
}

resource "aws_lb_listener" "php_app_https_to_http" {
  load_balancer_arn = aws_lb.php_app.arn
  port              = "80"
  protocol          = "HTTP"
  depends_on        = [aws_instance.bastion]
  #  ssl_policy        = "ELBSecurityPolicy-2016-08"
  #  certificate_arn   = "arn:aws:acm:us-east-2:990032074338:certificate/332fe32a-1a0a-4b8e-ad08-54a6ba710712"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

data "aws_route53_zone" "selected" {
  name         = "oyamkovyi.link"
  private_zone = false
}

resource "aws_route53_record" "php_app" {
  zone_id = data.aws_route53_zone.selected.id
  name    = "${var.env}.app"
  type    = "A"

  alias {
    name                   = aws_lb.php_app.dns_name
    zone_id                = aws_lb.php_app.zone_id
    evaluate_target_health = true
  }
  depends_on = [aws_instance.bastion]
}
