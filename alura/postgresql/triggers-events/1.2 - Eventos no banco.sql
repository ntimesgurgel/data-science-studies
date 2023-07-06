/*
* Inserir instrutores (com salários).
* Se o salário for maior do que a média, salvar um log
* Salvar outro log dizendo que fulano recebe mais do que x% da grade de instrutores. 
*/

CREATE TABLE instrutor (
	id SERIAL PRIMARY KEY,
	nome VARCHAR(255),
	salario DECIMAL(5,2)
);

INSERT INTO instrutor (nome, salario) 
VALUES ('nathan', 100.0);

INSERT INTO instrutor (nome, salario) 
VALUES ('rayanne', 200.0);

CREATE TABLE log_instrutores (
    id SERIAL PRIMARY KEY,
    informacao VARCHAR(255),
    momento_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION cria_instrutor() RETURNS TRIGGER AS 
$$ 
DECLARE
	media_salarial DECIMAL;
	instrutor_recebe_menos INTEGER DEFAULT 0;
	total_instrutores INTEGER DEFAULT 0;
	salario DECIMAL;
	percentual DECIMAL(5,2);
	logs_inseridos INTEGER;
	cursor_salarios refcursor;
BEGIN
	SELECT AVG(instrutor.salario) INTO media_salarial FROM instrutor WHERE id <> NEW.id;

	IF NEW.salario > media_salarial THEN
		INSERT INTO log_instrutores (informacao) VALUES (NEW.nome || ' recebe acima da média');
		GET DIAGNOSTICS logs_inseridos = ROW_COUNT;
	END IF;
	
	IF logs_inseridos > 1 THEN
		RAISE EXCEPTION 'quantidade de logs inconsistente';
	END IF;

	SELECT instrutores_internos(NEW.id) INTO cursor_salarios;
	
	LOOP
		FETCH cursor_salarios INTO salario;
		EXIT WHEN NOT FOUND;
		
		total_instrutores := total_instrutores + 1;
		RAISE NOTICE 'Salário inserido: % Salário do instrutor existente: %', NEW.salario, salario;

		IF NEW.salario > salario THEN
			instrutor_recebe_menos := instrutor_recebe_menos + 1;
		END IF;    
	END LOOP;

	percentual = instrutor_recebe_menos::DECIMAL / total_instrutores::DECIMAL * 100;
	ASSERT percentual < 100::DECIMAL, 'Instrutores novos não podem receber mais que os antigos';

	INSERT INTO log_instrutores (informacao) 
		VALUES (NEW.nome || ' recebe mais do que ' || percentual || '% da grade de instrutores');
	
	RETURN NEW;
END;
$$
LANGUAGE plpgsql;

DROP TRIGGER cria_log_instrutor ON instrutor;
CREATE OR REPLACE TRIGGER cria_log_instrutor BEFORE INSERT ON instrutor FOR EACH ROW EXECUTE FUNCTION cria_instrutor();

INSERT INTO instrutor (nome, salario) VALUES ('outro instrutor 2', 50);

SELECT * FROM instrutor;
SELECT * FROM log_instrutores;

BEGIN;
INSERT INTO instrutor (nome, salario) VALUES ('maria', 700);
ROLLBACK;