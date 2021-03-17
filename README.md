# Subindo uma instancia Postgres com Terraform


# Pré-requisitos
AWS-CLI - Configurado e apontado para conta a qual quer subir a instancia de banco. REF:
https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html
Projeto realizado com as versão: aws-cli/1.18.69

Configuração de rede criada, para receber o Postgres e com um security group aceitando conexão somente pro seu IP:
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_VPC.html

PS*1: Essa parte foi a que tive mais dificuldade de subir, segui muito a doc da AWS pra aplicar um configuração padrão então toda a parte de network do postgres apliquei sem muito conhecimento do que tava fazendo, a única parte que compreendi qual a função seria a do Security Grou, onde posso controlar o que irá acessar o meu banco. Agora a parte de criação de VPC e Subnet Groups eu segui a criação padrão da AWS na Doc.

PS*2 Para subir os projetos você precisará mudar as variáveis das respectíveis Subnet e SecurityGroup para os criados anteriormente.

Criação de role IAM para Monitoramento Avançado.REF:
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring.OS.html
Foi criado uma role para poder fazer uso do "Enhanced Monitoring" segundo a documentação acima, foi possível realizar somente via console(Interface Gráfica).

# Decisão dos parâmetros:

Seguindo a doc do Terraform: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance, foi criado um script pra levantar  uma instancia rds com os seguintes parametros:
  `instance_class       = "db.t2.micro"`
Foi usado uma instancia t2.micro, pois a mesma é a única versão free dentro da AWS. Em ambiente produtivo recomendaria uma versão maior com pelo menos 8GB de Ram e 4 Núcleos de CPU.

`#multi_az            = true`
Parâmetro para ativar o multi_az comentado pois o mesmo não se encontra na versão free da AWS.

`parameter_group_name = "config-banco"`
Parâmetro que vincula um grupo de parâmetros de banco ao database, foi criado no mesmo script e será comentado mais abaixo

  `skip_final_snapshot  = true
  #delete_automated_backups = false`
Parâmetro que diz a AWS para não criar backup e manter backups após deleção, propósito dele está exclusivo para uso de testes não havendo necessidade de ficar salvando backups , não recomendado em ambientes produtivos.

 `identifier           = "instanciateste"
 
  name                 = "teste"
  
  username             = "postgres"
  
  password             = "senhadodb"
  
  port                 = 5432 `
Informações da instância parâmetros de conexão e etc, name representa o nome do banco a ser criado , caso o mesmo não seja especificado não será criado um banco junto ao script de criação de instância.

 `maintenance_window   = "Sun:00:00-Sun:01:59"
  backup_window        = "02:00-05:00"
  backup_retention_period = 7`
  Janela de backup e manutenção respectivamente, estão setadas em fuso horário diferente, sendo 21:00 as 22:59 sábado, e o backup das 23:00 ás 02:00. Período de retenção de backup de 7 dias, tba usado para point in time recovery. 

  `vpc_security_group_ids  =["sg-0449f712679e8775f"]
  db_subnet_group_name    ="subnetdb"
  publicly_accessible = true`
Parâmetro usado para definir o security group e o dbsubnet usado no banco.

  `performance_insights_enabled = true
  performance_insights_retention_period = 7`
Parâmetro usado para definir o uso do performance Insights 


 `auto_minor_version_upgrade = false
  allow_major_version_upgrade = false`
Parâmetro que define se o banco pode iniciar atualização sozinho, apesar da AWS ser uma nuvem incrível , acredito que isso não deva ser realizado em ambiente produtivo sem testes devidamente realizados e com acompanhamento de um profissional.


`enabled_cloudwatch_logs_exports = ["postgresql"]`
Èxporta os logs para o CloudWatch, necessário para os alertas de auditoria.

  `monitoring_interval  = 5
  monitoring_role_arn  = "arn:aws:iam::434761106183:role/monitoramento_avancado"`
Parâmetro que define o monitoramento avançado.
