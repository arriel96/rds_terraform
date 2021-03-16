terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}


resource "aws_db_instance" "default" {
  #######################################################
  ##########Configurações da máquina e versão############
  ##Usei a última versão.
  ##As configurações da máquina são pra subir um banco free-tier na RDS
  ##Como estou testando em uma conta free tier não consigo trazer as configurações recomendadas para o Projeto pedido.
  allocated_storage    = 20
  instance_class       = "db.t2.micro"
  parameter_group_name = "config-banco"

  #Propósito de não salvar bkp durante testes.
  skip_final_snapshot  = true
  #delete_automated_backups = false

  identifier           = "readteste"
  port                 = 5432
  replicate_source_db  = "instanciateste"
  

  ###
  ##Criei um securitu group manual com a regra de entrada tendo somente permissão 
  # para o meu IP e somente na porta 5432
  ###
  vpc_security_group_ids  =["sg-0449f712679e8775f"]
  publicly_accessible = true

  performance_insights_enabled = true
  performance_insights_retention_period = 7
  
  monitoring_interval  = 5
  monitoring_role_arn  = "arn:aws:iam::434761106183:role/monitoramento_avancado"

}