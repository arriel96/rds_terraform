CREATE TABLE usuarios (
  id SERIAL NOT NULL,
  data_criacao TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
  nome VARCHAR(250) NOT NULL,
  email VARCHAR(250) NOT NULL,
  senha VARCHAR(255) NOT NULL,
  data_nascimento DATE NOT NULL,
  cpf VARCHAR(11) NOT NULL,
  CONSTRAINT pk_usuario PRIMARY KEY (id),
  CONSTRAINT un_email_usuario UNIQUE (email)
);


CREATE TABLE enderecos (
  id SERIAL NOT NULL,
  id_usuario INT NOT NULL,
  data_criacao TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
  estado CHAR(2) NOT NULL,
  cidade VARCHAR(100) NOT NULL,
  rua VARCHAR(300) NOT NULL,
  numero VARCHAR(10) NOT NULL,
  complemento TEXT,
  CONSTRAINT pk_endereco PRIMARY KEY (id),
  CONSTRAINT fk_endereco_usuario FOREIGN KEY (id_usuario) 
   REFERENCES usuarios (id)
  
);

CREATE TABLE produtos (
  id SERIAL NOT NULL,
  id_usuario INT NOT NULL,
  nome VARCHAR(250) NOT NULL,
  descricao TEXT NOT NULL,
  preco_centavos INT NOT NULL,
  data_criacao TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
  status VARCHAR(50) NOT NULL,
  CONSTRAINT pk_produto PRIMARY KEY (id),
  CONSTRAINT fk_produto_usuario FOREIGN KEY (id_usuario) 
   REFERENCES usuarios (id)
);

CREATE TABLE sacolas (
  id SERIAL NOT NULL,
  id_usuario INT NOT NULL,
  preco_centavos INT NOT NULL,
  status VARCHAR(80) NOT NULL,
  data_criacao TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
  data_compra TIMESTAMP WITHOUT TIME ZONE,
  CONSTRAINT pk_sacola PRIMARY KEY (id),
  CONSTRAINT fk_sacola_usuario FOREIGN KEY (id_usuario) 
   REFERENCES usuarios (id)

);

CREATE TABLE sacola_produtos (
  id SERIAL NOT NULL,
  id_produto INT NOT NULL,
  id_sacola  INT NOT NULL,
  data_criacao TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_sacola_produto PRIMARY KEY (id),
  CONSTRAINT fk_sacola_produto_produto FOREIGN KEY (id_produto) 
   REFERENCES produtos (id),
  CONSTRAINT fk_sacola_produto_sacola FOREIGN KEY (id_sacola) 
   REFERENCES sacolas (id)
);

CREATE TABLE envio (
  id SERIAL NOT NULL,
  id_endereco INT NOT NULL,
  id_sacola INT NOT NULL,
  preco_centavos INT NOT NULL,
  data_criacao TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
  data_postagem TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  codigo_rastreio VARCHAR(100),
  servico VARCHAR(100),
  status VARCHAR(80),
  CONSTRAINT pk_envio PRIMARY KEY (id),
  CONSTRAINT fk_envio_endereco FOREIGN KEY (id_endereco) 
   REFERENCES produtos (id),
  CONSTRAINT fk_envio_sacola FOREIGN KEY (id_sacola) 
   REFERENCES sacolas (id)
);


/*Funções de controle*/

CREATE FUNCTION trg_funcao_add_preco_sacola()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN

    UPDATE  sacolas 
    SET     preco_centavos = sacolas.preco_centavos + prod.preco_centavos
    FROM    (
            SELECT  preco_centavos
            FROM    produtos
            WHERE   id=new.id_produto
      ) as prod
    WHERE   id = new.id_sacola;

    RETURN NEW;
END;
$BODY$;


CREATE TRIGGER trigger_add_preco_sacola
    AFTER INSERT
    ON sacola_produtos
    FOR EACH ROW
    EXECUTE PROCEDURE trg_funcao_add_preco_sacola();


CREATE FUNCTION trg_funcao_remove_prod()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
  x INT;
BEGIN
    IF (old.status ='aberta' and new.status ='fechada') THEN
    FOR x IN 
        SELECT  id_produto 
        FROM    sacola_produtos
        WHERE   id_sacola=old.id
    LOOP
        UPDATE  produtos
        SET     status='comprado'
        WHERE   id=x;

    END LOOP;

    END IF;
    RETURN NEW;

END;
$BODY$;


CREATE TRIGGER trigger_remove_prod
    AFTER UPDATE 
    ON sacolas
    FOR EACH ROW
    EXECUTE PROCEDURE trg_funcao_remove_prod();

CREATE FUNCTION trg_funcao_block_update_prod()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
  x INT;
BEGIN
    IF (old.status ='comprado' and old.status ='removido') THEN
      RAISE EXCEPTION 'Produto Indisponível pra compra'
      USING ERRCODE = 'PEBRR01';
    END IF;

    RETURN new;

END;
$BODY$;


CREATE TRIGGER trigger_block_update_prod
    BEFORE UPDATE 
    ON produtos
    FOR EACH ROW
    EXECUTE PROCEDURE trg_funcao_block_update_prod();



CREATE OR REPLACE FUNCTION random_entre(low INT ,high INT) 
   RETURNS INT AS
$$
BEGIN
   RETURN floor(random()* (high-low + 1) + low);
END;
$$ language 'plpgsql' 
STRICT;


/*Parâmetros do autovaccum e analyze*/

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




/*Inserts*/

do $$ 
DECLARE
    x int;
    y INT;
BEGIN
  
    FOR x IN 1..10000
    LOOP
        y=0;
        INSERT INTO usuarios (nome,email,senha,data_nascimento,cpf)
        VALUES
        ('Nome legal'||x, 'meuemail'||x||'@gmail.com','SuperSenhaCriptografadaComHash','1960-09-21','01212314758')
        RETURNING id INTO y;

        INSERT INTO enderecos (id_usuario,estado,cidade,rua,numero,complemento)
        VALUES
        (y, 'SP','Sao Paulo','Av: Rua','1745','Ap 02');

    END LOOP;

END$$;


do $$ 
DECLARE
    x int;
    y INT;
    z INT;
BEGIN
    SELECT  min(id),
            max(id) 
    INTO    y,z
    FROM usuarios;

    FOR x IN 1..100000
    LOOP
        
        INSERT INTO produtos (id_usuario,nome,descricao,preco_centavos,status)
        VALUES(random_entre(y,z),'Produto Legal '||x,'Super descrição do item '||x,2000,'disponivel');

        INSERT INTO produtos (id_usuario,nome,descricao,preco_centavos,status)
        VALUES(random_entre(y,z),'Produto Massa '||x,'Super descrição do item '||x,20000,'disponivel');

        INSERT INTO produtos (id_usuario,nome,descricao,preco_centavos,status)
        VALUES(random_entre(y,z),'Produto OK '||x,'Super descrição do item '||x,6000,'disponivel');

        INSERT INTO produtos (id_usuario,nome,descricao,preco_centavos,status)
        VALUES(random_entre(y,z),'Produto Ruim '||x,'Super descrição do item '||x,5500,'disponivel');

        INSERT INTO produtos (id_usuario,nome,descricao,preco_centavos,status)
        VALUES(random_entre(y,z),'Produto Nada mal '||x,'Super descrição do item '||x,1999,'disponivel');

        INSERT INTO produtos (id_usuario,nome,descricao,preco_centavos,status)
        VALUES(random_entre(y,z),'Produto especifico '||x,'Super descrição do item '||x,3899,'disponivel');

        INSERT INTO produtos (id_usuario,nome,descricao,preco_centavos,status)
        VALUES(random_entre(y,z),'Produto Generico '||x,'Super descrição do item '||x,5560,'disponivel');

        INSERT INTO produtos (id_usuario,nome,descricao,preco_centavos,status)
        VALUES(random_entre(y,z),'Produto muito usado '||x,'Super descrição do item '||x,7090,'disponivel');

        INSERT INTO produtos (id_usuario,nome,descricao,preco_centavos,status)
        VALUES(random_entre(y,z),'Produto pouco usado '||x,'Super descrição do item '||x,8000,'disponivel');

        INSERT INTO produtos (id_usuario,nome,descricao,preco_centavos,status)
        VALUES(random_entre(y,z),'Produto final '||x,'Super descrição do item '||x,8000,'disponivel');
        
    END LOOP;

END$$;


do $$ 
DECLARE
    x int;
    min_id_usu INT;
    max_id_usu INT;

    id_prod_1 INT;
    id_prod_2 INT;
    id_prod_3 INT;

    id_sac INT;
BEGIN
    SELECT  min(id),
            max(id) 
    INTO    min_id_usu, 
            max_id_usu
    FROM usuarios;

    FOR x IN 1..1000
    LOOP

        --Inicio Sacolas com compra concluída


        id_sac=0;

        INSERT INTO sacolas (id_usuario,preco_centavos,status)
        VALUES (random_entre(min_id_usu,MAX_id_usu) ,0,'aberta')
        RETURNING id INTO id_sac;

        INSERT INTO sacola_produtos (id_produto,id_sacola)
        SELECT id,id_sac
        FROM    produtos 
        WHERE   status='disponivel'
        LIMIT   3;


        UPDATE sacolas 
        SET status ='fechada'
        WHERE id=id_sac;

        --Fim Sacolas com compra concluída

        --Inicio Sacolas Cancelada

        id_sac=0;   

        INSERT INTO sacolas (id_usuario,preco_centavos,status)
        VALUES (random_entre(min_id_usu,MAX_id_usu) ,0,'aberta')
        RETURNING id INTO id_sac;

        INSERT INTO sacola_produtos (id_produto,id_sacola)
        SELECT id,id_sac
        FROM    produtos 
        WHERE   status='disponivel'
        LIMIT   1;

        --Fim Sacolas Cancelada

        --Inicio Sacolas em aberto


        id_sac=0;   

        INSERT INTO sacolas (id_usuario,preco_centavos,status)
        VALUES (random_entre(min_id_usu,MAX_id_usu) ,0,'aberta')
        RETURNING id INTO id_sac;


        INSERT INTO sacola_produtos (id_produto,id_sacola)
        SELECT id+x,id_sac
        FROM    produtos 
        WHERE   status='disponivel'
        LIMIT   2;

        --Fim Sacolas em aberto

        
    END LOOP;

END$$;


CREATE USER usarioconsulta WITH PASSWORD 'SuperSenhadoUsuario';
GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO usarioconsulta;


