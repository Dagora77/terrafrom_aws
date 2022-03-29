#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2 -y
sudo yum install -y httpd mariadb-server
sudo systemctl start httpd
sudo systemctl enable httpd
sudo aws s3 sync s3://php-app-epam/php-mysql-crud-master /var/www/html/
sudo aws s3 cp s3://php-app-epam/db.sh /home/ec2-user/
sudo chmod +x /home/ec2-user/db.sh
sed -i -e 's/\r$//' /home/ec2-user/db.sh
/home/ec2-user/db.sh
mysql -u root -h ${aws_db_instance.PHP_app.endpoint}-php-app.cvoels9nqczd.us-east-2.rds.amazonaws.com --password=5526c03ba6 -e "create database php_mysql_crud;"
mysql -u root -h ${aws_db_instance.PHP_app.endpoint}-php-app.cvoels9nqczd.us-east-2.rds.amazonaws.com --password=5526c03ba6 -e "use php_mysql_crud; CREATE TABLE task(id int(11) NOT NULL, title varchar(255) COLLATE utf8_unicode_ci NOT NULL, description text COLLATE utf8_unicode_ci NOT NULL, created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;"
