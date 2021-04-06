# Subindo uma instancia Postgres com Terraform


# Pré-requisitos
AWS-CLI - Configurado e apontado para conta a qual quer subir a instancia de banco. <br /> Referências:<br />
https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html
<br />
Projeto realizado com as versão: aws-cli/1.18.69

Configuração de rede criada, para receber o Postgres e com um security group aceitando conexão somente pro seu IP:<br />
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_VPC.html
<br />
PS*2 Para subir o projeto você precisará mudar a variável de SecurityGroup para o criado anteriormente.
<br />
<br />
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
  Janela de backup e manutenção respectivamente, estão setadas em fuso horário diferente, sendo 21:00 as 22:59 sábado, e o backup das 23:00 ás 02:00. Período de retenção de backup de 7 dias, também usado para point in time recovery. 
<br />
_________________________________________________________________________________________________________
  ```bash
  vpc_security_group_ids  =["sg-0449f712679e8775f"]
  publicly_accessible = true
  ```
Parâmetro usado para definir o security group usado no banco.
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
<br />Referências:<br />
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
Referências:<br />
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

# Parâmetros autovaccum:

Além dos parâmetros acima foi modificado os parâmetros de analyze e vaccum das tabelas, lembrando uqe a formula seria thresold+numero_de_tupla*scale_factor.
Seguindo essas docs:
https://www.cybertec-postgresql.com/en/tuning-autovacuum-postgresql/
https://www.2ndquadrant.com/en/blog/autovacuum-tuning-basics/

```
ALTER TABLE usuarios SET (autovacuum_vacuum_scale_factor = 0,
                                      autovacuum_vacuum_threshold = 10000,
                                      autovacuum_analyze_scale_factor = 0,
                                      autovacuum_analyze_threshold = 10000
                                      );
ALTER TABLE enderecos SET (autovacuum_vacuum_scale_factor = 0,
                                      autovacuum_vacuum_threshold = 10000,
                                      autovacuum_analyze_scale_factor = 0,
                                      autovacuum_analyze_threshold = 10000
                                      );
ALTER TABLE produtos SET (autovacuum_vacuum_scale_factor = 0,
                                      autovacuum_vacuum_threshold = 100000,
                                      autovacuum_analyze_scale_factor = 0,
                                      autovacuum_analyze_threshold = 100000
                                      );
ALTER TABLE sacolas SET (autovacuum_vacuum_scale_factor = 0,
                                      autovacuum_vacuum_threshold = 50000,
                                      autovacuum_analyze_scale_factor = 0,
                                      autovacuum_analyze_threshold = 50000
                                      );
ALTER TABLE sacola_produtos SET (autovacuum_vacuum_scale_factor = 0,
                                      autovacuum_vacuum_threshold = 50000,
                                      autovacuum_analyze_scale_factor = 0,
                                      autovacuum_analyze_threshold = 50000
                                      );
ALTER TABLE envio SET (autovacuum_vacuum_scale_factor = 0,
                                      autovacuum_vacuum_threshold = 30000,
                                      autovacuum_analyze_scale_factor = 0,
                                      autovacuum_analyze_threshold = 30000
                                      );
```
Foi removido zerado o factor para que trabalhemos somente com números inteiros. Autovaccum em si ja chama o analyze mas o mesmo só ocorre quando temos um X numero de tuplas mortas enquanto o analyze pode ser contado a partir dos números de operações: INSERT,UPDATE,DELETE (Note que insert não gera tuplas mortas).</br>
O valor a ser setado nesses parâmetros vai de acordo com o uso esperado das tabelas, seu crescimento e valor de linhas atuais.</br>
Para um controle melhor achei melhor usar valores exatos no threshold.</br>

Tabela usuarios: Valor definido em 10.000 , pois não existem muitos problemas de performance em tabelas com esse valor ou menor, não se espera um crescimento muito alto nessa tabela (podem surgir alguns picos mas normalmente é uma entrada constante e não muito alta de volume, além de estar começando em um valor ok).</br>

Tabela enderecos: Segue o mesmo crescimento da usuário, um usuário pode ter N enderecos , mas não se espera que ela ultrapasse 5x o tamanho da tabela usuário. Valor inicial o mesmo da tabela usuário.</br>

Tabela de produtos: Foi definido um número de 100.000 pois a mesma seria a tabela mas frequentemente utilizada/atualizada e com maior número de dados.</br>

Tabela de sacolas:Foi definido em 50000, ela deve acompanhar o crescimento da tabela produtos, determina o numero de vendas realizadas/canceladas na aplicação. Como não tem o mesmo numero de dados que a Produtos.</br>

Tabela de sacola_produtos: Foi definido em 50000, ela deve acompanhar o crescimento da tabela sacolas, determina o numero de vendas realizadas/canceladas na aplicação. Como não tem o mesmo numero de dados que a Produtos.</br>

Tabela de envios:  Foi definido um valor de 30000. Inicialmente não tem dados , mas a mesma não deve superar o numero de sacolas , visto que só ocorrerá no caso onde o processo da sacola seja concluído.</br>
Referência:</br>
https://www.percona.com/blog/2018/08/10/tuning-autovacuum-in-postgresql-and-autovacuum-internals/ </br>
https://cybertec-postgresql.com/en/tuning-autovacuum-postgresql/ </br>
https://www.netiq.com/documentation/cloud-manager-2-5/ncm-install/data/vacuum.html </br>
https://www.postgresql.org/docs/12/runtime-config-autovacuum.html </br>

# Executando:

  Com os pré-requisitos montados, baixe a pasta do projeto.</br>
  Dentro da pasta rds-write crie cópias dos arquivos init.sh.sample e variables.tf.sample e renomeie os mesmos para init.sh e variables.tf respectivamente.</br>
  Depois use o comandar para aplicar permissão de execução no arquivo init.sh:</br>
  ```bash
   cp init.sh.sample init.sh
   cp variables.tf.sample variables.tf
   chmod 550 init.sh
  ``` 
  Edite o arquivo variables.tf para definir : usuario, senha , nome da instancia(nao pode conter letra maiscula), nome do banco e id do security group.</br>
  Use os comandos terraform para levantar o banco:</br>

  ```bash
  terraform init
  terraform apply
  ```
  Após alguns minutos a instância do banco deve subir sem erro.</br>

  Após a instância tiver pronta edite as variaveis do arquivo init.sh com as informações de conexão do banco.</br>

  Execute o arquivo init.sh, que irá executar um script para subir a base teste, criar role de auditoria , mudar os parametros do banco para auditoria, criar as metricas de auditoria para receber alertas em cima de drop e delete, reiniciar o banco de dados.</br>

  Repita o processo do arquivo variables.tf.sample na pasta rds-read:</br>
  ```bash
  cp variables.tf.sample variables.tf
  ``` 
  
  Após editar as varivéis execute o terraform para levantar a instancia de read-only:</br>
  ```bash
  terraform init
  terraform apply
  ``` 

  Após a execução do comando init.sh , os alertas já podem ser configurados na CloudWatch para ser enviados via E-mail. Isso pode acontecer ao mesmo tempo que a instância de read-only sobe.</br></br>

  Pelo console siga os passos da Doc da AWS para criar alarmes em cima das metricas criadas pelo scrip, são elas: DropCount e DeleteCount.</br>
  https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Create-alarm-on-metric-math-expression.html
  </br>Dados do alarme:

  ```bash
  Estatistica: Soma
  Período: 15min
  Condições: Estático
  Maior/Igual: 1
  ```

  Aplique a mesma configuração de alerta nas duas metricas criadas.

# PGBench:

Usando essas documentações como base foi aplicado o PGBench para análise. Doc: </br>
https://www.cloudbees.com/blog/tuning-postgresql-with-pgbench/ </br>


Comandos executados:
```bash
pgbench -i -h host -p 5432 -U usuario banco
pgbench -c 10 -j 4 -t 100 -h host -p 5432 -U usuario -d nome_do_banco
```

</br></br>
Primeira execuxão:
```
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 2
number of transactions per client: 1000
number of transactions actually processed: 10000/10000
latency average = 3787.990 ms
tps = 2.639923 (including connections establishing)
tps = 2.640737 (excluding connections establishing)
```

Notei que teve uma latência alta e um baixo número de transações por segundo, alterei o parâmetro de shared_buffers como blog, mas aparentemente não houve muita diferença nos valores. Esse resultado pode ser efeito da máquina fraca da instância ou da latência entre o meu PC (onde foi executado) e a instância. De qualquer forma procurei alguns artigos relacionados e não achei muita coisa sobre como aumentar a performance do PGBench.
Fica o último resultado após a mudança do parametro de shared_buffers

```
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 4
number of transactions per client: 100
number of transactions actually processed: 1000/1000
latency average = 3773.549 ms
tps = 2.650025 (including connections establishing)
tps = 2.658245 (excluding connections establishing)
statement latencies in milliseconds:
         0.056  \set aid random(1, 100000 * :scale)
         0.058  \set bid random(1, 1 * :scale)
         0.046  \set tid random(1, 10 * :scale)
         0.042  \set delta random(-5000, 5000)
       184.889  BEGIN;
       185.853  UPDATE pgbench_accounts SET abalance = abalance + :delta WHERE aid = :aid;
       185.823  SELECT abalance FROM pgbench_accounts WHERE aid = :aid;
      1053.514  UPDATE pgbench_tellers SET tbalance = tbalance + :delta WHERE tid = :tid;
      1668.840  UPDATE pgbench_branches SET bbalance = bbalance + :delta WHERE bid = :bid;
       185.290  INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (:tid, :bid, :aid, :delta, CURRENT_TIMESTAMP);
       186.173  END;

```
</br>
</br>
PS:</br>
Aparentmente o comando: </br> 

``` 
GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO usarioconsulta;
``` 
</br>

Não funciona para tabela futuras, para funcionar em tabelas futuras deve se alterar a permissão padrão do schema:

```
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO usarioconsulta;
```
</br>
Não adicionei no projeto pois ja tinha feito a entrega do mesmo , mas fica a possível solução.
