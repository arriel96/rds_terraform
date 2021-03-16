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

