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

resource "aws_db_parameter_group" "config-banco" {
  name        = "config-banco"
  family      = "postgres12"
  description = "Configuracoes dos parametros do banco"

  parameter {
    name  = "max_connections"
    value = 105
    apply_method = "pending-reboot"
  }

  parameter {
      name  = "client_encoding"
      value = "utf8"
      apply_method = "pending-reboot"
  }

  #######################################################
  ##########Configurações do autovacuum############
  ##estou setando os valores padrões por motivos de falta de recurso
  ##As configurações da máquina são pra subir um banco free-tier na RDS
  ##Como estou testando em uma conta free tier não consigo trazer as configurações recomendadas para o Projeto pedido.
  ##Recomendação sobre auto-vaccum: Tabela maiores: menos workers + memoria
  ##Recomendação sobre auto-vaccum: Varias tabelas pequenas: mais workers - memoria
  ##Recomendação sobre auto-vaccum: Usar uma quantidade de memória disponível na máquina. Analisar memória disponível
  #no banco(total de memória sobrando durante uso do banco) onde:
  #Numero de Workers * Memoria alocada <= Memoria sobrando
  ##Recomendação da AWS:
  #Sistemas grandes: 1 a 2 Gigabytes
  #Sistemas Muito grandes: 2 a 4 Gigabytes

  parameter {
      name  = "autovacuum"
      value = true
      apply_method = "pending-reboot"
  }

  parameter {
      name  = "maintenance_work_mem"
      value = 65536
      apply_method = "pending-reboot"
  }

  parameter {
      name  = "autovacuum_max_workers"
      value = 3
      apply_method = "pending-reboot"
  }

  parameter {
      name  = "rds.adaptive_autovacuum "
      value = 1
      apply_method = "immediate"
  }

}

resource "aws_db_instance" "default" {
  #######################################################
  ##########Configurações da máquina e versão############
  ##Usei a última versão.
  ##As configurações da máquina são pra subir um banco free-tier na RDS
  ##Como estou testando em uma conta free tier não consigo trazer as configurações recomendadas para o Projeto pedido.
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "12.5"
  instance_class       = "db.t2.micro"
  parameter_group_name = "config-banco"
  #multi_az            = true

  #Propósito de não salvar bkp durante testes.
  skip_final_snapshot  = true
  #delete_automated_backups = false

  identifier           = var.instance_name
  name                 = "teste"
  username             = var.usuario
  password             = var.senha
  port                 = 5432
  
  
  maintenance_window   = "Sun:00:00-Sun:01:59"
  backup_window        = "02:00-05:00"
  backup_retention_period = 7

  ###
  ##Criei um securitu group manual com a regra de entrada tendo somente permissão 
  # para o meu IP e somente na porta 5432
  ###
  vpc_security_group_ids  =[var.seg_group]
  publicly_accessible = true

  performance_insights_enabled = true
  performance_insights_retention_period = 7
  auto_minor_version_upgrade = false
  allow_major_version_upgrade = false

  enabled_cloudwatch_logs_exports = ["postgresql"]

  
  
  monitoring_interval  = 5
  monitoring_role_arn  = "arn:aws:iam::434761106183:role/monitoramento_avancado"



}