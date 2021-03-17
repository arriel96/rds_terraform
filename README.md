# Subindo uma instancia Postgres com Terraform


# Pré-requisitos
AWS-CLI - Configurado e apontado para conta a qual quer subir a instancia de banco. <br /> Referências:<br />
https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html
<br />
Projeto realizado com as versão: aws-cli/1.18.69

Configuração de rede criada, para receber o Postgres e com um security group aceitando conexão somente pro seu IP:<br />
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_VPC.html
<br />
PS*1: Essa parte foi a que tive mais dificuldade de subir, segui muito a doc da AWS pra aplicar um configuração padrão então toda a parte de network do postgres apliquei sem muito conhecimento do que tava fazendo, a única parte que compreendi qual a função seria a do Security Grou, onde posso controlar o que irá acessar o meu banco. Agora a parte de criação de VPC e Subnet Groups eu segui a criação padrão da AWS na Doc.
<br />
PS*2 Para subir os projetos você precisará mudar as variáveis das respectíveis Subnet e SecurityGroup para os criados anteriormente.
<br />
Criação de role IAM para Monitoramento Avançado. <br />
Referências:<br />
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring.OS.html
<br />
Foi criado uma role para poder fazer uso do "Enhanced Monitoring" segundo a documentação acima, foi possível realizar somente via console(Interface Gráfica).

# Decisão dos parâmetros:

Seguindo a doc do Terraform: 

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance

Foi criado um script pra levantar  uma instancia rds com os seguintes parametros:
<br />
_________________________________________________________________________________________________________

  ```bash
  instance_class       = "db.t2.micro"
  ```
Foi usado uma instancia t2.micro, pois a mesma é a única versão free dentro da AWS. Em ambiente produtivo recomendaria uma versão maior com pelo menos 8GB de Ram e 4 Núcleos de CPU.
<br />
_________________________________________________________________________________________________________

```bash
#multi_az            = true
```
Parâmetro para ativar o multi_az comentado pois o mesmo não se encontra na versão free da AWS.
<br />
_________________________________________________________________________________________________________

```bash
parameter_group_name = "config-banco"
```
Parâmetro que vincula um grupo de parâmetros de banco ao database, foi criado no mesmo script e será comentado mais abaixo
<br />
_________________________________________________________________________________________________________
  ```bash
  skip_final_snapshot  = true
  #delete_automated_backups = false
  ```
Parâmetro que diz a AWS para não criar backup e manter backups após deleção, propósito dele está exclusivo para uso de testes não havendo necessidade de ficar salvando backups , não recomendado em ambientes produtivos.
<br />
_________________________________________________________________________________________________________
 ```bash
  identifier           = "instanciateste"
  name                 = "teste"
  username             = "postgres"
  password             = "senhadodb"
  port                 = 5432
  ```
Informações da instância parâmetros de conexão e etc, name representa o nome do banco a ser criado , caso o mesmo não seja especificado não será criado um banco junto ao script de criação de instância.
<br />
_________________________________________________________________________________________________________
 ```bash
  maintenance_window   = "Sun:00:00-Sun:01:59"
  backup_window        = "02:00-05:00"
  backup_retention_period = 7
  ```
  Janela de backup e manutenção respectivamente, estão setadas em fuso horário diferente, sendo 21:00 as 22:59 sábado, e o backup das 23:00 ás 02:00. Período de retenção de backup de 7 dias, tba usado para point in time recovery. 
<br />
_________________________________________________________________________________________________________
  ```bash
  vpc_security_group_ids  =["sg-0449f712679e8775f"]
  db_subnet_group_name    ="subnetdb"
  publicly_accessible = true
  ```
Parâmetro usado para definir o security group e o dbsubnet usado no banco.
<br />
_________________________________________________________________________________________________________
  ```bash
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  ```
Parâmetro usado para definir o uso do performance Insights 
<br />
_________________________________________________________________________________________________________
 ```bash
  auto_minor_version_upgrade = false
  allow_major_version_upgrade = false
  ```
Parâmetro que define se o banco pode iniciar atualização sozinho, apesar da AWS ser uma nuvem incrível , acredito que isso não deva ser realizado em ambiente produtivo sem testes devidamente realizados e com acompanhamento de um profissional.
<br />
_________________________________________________________________________________________________________
```bash
enabled_cloudwatch_logs_exports = ["postgresql"]
```
Exporta os logs para o CloudWatch, necessário para os alertas de auditoria.
<br />
_________________________________________________________________________________________________________
  ```bash
  monitoring_interval  = 5
  monitoring_role_arn  = "arn:aws:iam::434761106183:role/monitoramento_avancado"
  ```
Parâmetro que define o monitoramento avançado. Será coletado dados de 5 a 5 minutos.

# Parâmetros de banco

Parâmetros definidos no ParametersGroup, que definim o comportamento do banco


```bash
$ name  = "max_connections"
$ value = 105
$ apply_method = "pending-reboot"
``` 
Segundo algumas documentações o parâmetro de max_conections varia de acordo com o uso do banco, isso pode variar com implementação da aplicação, número de rotinas que são executados e processos background do mesmo. Como não tenho noção desses números mante o max conections de acordo com o padrão da AWS. 
<br />Referencia:<br />
https://www.cybertec-postgresql.com/en/tuning-max_connections-in-postgresql/<br />
https://cloud.ibm.com/docs/databases-for-postgresql?topic=databases-for-postgresql-managing-connections<br />
https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Managing.html#AuroraPostgreSQL.Managing.MaxConnections 
<br />
_________________________________________________________________________________________________________

```bash
 name  = "autovacuum"
 value = true
 apply_method = "pending-reboot"
```
Parâmetro usado para ligar o autovacuum no servidor do banco. Autocacuum é um procedimento de remoção de linhas mortas e rbalancemento das linhas da tabela/index , o no meio desse procedimento também é realyzado o analyze(coleta de estatísticas para o optimizador). 
<br />
_________________________________________________________________________________________________________

```bash
 name  = "maintenance_work_mem"
 value = 180536
 apply_method = "pending-reboot"
``` 
Parâmetro usado para definir o uso de memória das rotinas de manutenção e é definido em KB. Foi definido os valores onde antes existia 65MB  e 3 workers, como temos somente uma tabela grande e outras menores , de acrodo com a documentação eu diminui o numero de workers e aumentei a memória, por motivo de falta de recurso foi usado a mémoria padrão como base. Recomendações da AWS:
  - Tabela maiores: menos workers + memoria
  - Varias tabelas pequenas: mais workers - memoria
  - Usar uma quantidade de memória disponível na máquina. Analisar memória disponível
  - Numero de Workers * Memoria alocada <= Memoria sobrando
  - Sistemas grandes: 1 a 2 Gigabytes
  - Sistemas Muito grandes: 2 a 4 Gigabytes
Auto-vaccum é sempre executado quando deadtuples=>autovacuum_vacuum_threshold + (scale_factor da tabela * numero total de tuplas).<br />
Referencia:<br />
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.Autovacuum.html <br />
https://aws.amazon.com/pt/blogs/database/a-case-study-of-tuning-autovacuum-in-amazon-rds-for-postgresql/ <br />
https://www.datadoghq.com/blog/aws-rds-postgresql-monitoring/ <br />
https://www.2ndquadrant.com/en/blog/autovacuum-tuning-basics/ <br />
_________________________________________________________________________________________________________

```bash
 name  = "autovacuum_max_workers"
 value = 1
 apply_method = "pending-reboot"
``` 
Parâmetro usado para definir o número de workers de autovaccum, usar recomendações acima.
<br />
_________________________________________________________________________________________________________

```bash
 name  = "rds.adaptive_autovacuum"
 value = 1
 apply_method = "immediate"
``` 
Além dos parâmetros acima existem alguns outros parâmetros dinâmicos a respeito do auto-vaccum, mas este parâmetro do RDS é um parâmetro inteligente que atualiza esses valores conforme a necessidade.
