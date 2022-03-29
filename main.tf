provider "aws" {
  region = var.region
}

module "php_app" {
  source = "./modules/php_app"

}


module "php_app_qa" {
  source        = "./modules/php_app"
  env           = "qa"
  instance_type = "t3.micro"
}

/*
vpc_id              = module.php_app.vpc_id
public_subnet_id_a  = module.php_app.public_subnet_id_a
public_subnet_id_b  = module.php_app.public_subnet_id_b
private_subnet_id_a = module.php_app.private_subnet_id_a
private_subnet_id_b = module.php_app.private_subnet_id_b
env_security_group  = module.php_app.env_security_group
aws_db_php          = module.php_app.aws_db_php
aws_db_php_endpoint = module.php_app.aws_db_php_endpoint
*/
