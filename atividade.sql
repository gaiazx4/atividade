DROP TABLE IF EXISTS historico_partidas CASCADE;
DROP TABLE IF EXISTS partidas CASCADE;
DROP TABLE IF EXISTS modalidades CASCADE;
DROP TABLE IF EXISTS jogadores CASCADE;



CREATE TABLE jogadores (
    id_jogador SERIAL PRIMARY KEY,
    nickname VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    senha TEXT NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CHECK (length(nickname) >= 3)
);



CREATE TABLE modalidades (
    id_modalidade SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    categoria VARCHAR(30) NOT NULL
);



CREATE TABLE partidas (
    id_partida SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    id_jogador INTEGER NOT NULL,
    id_modalidade INTEGER NOT NULL,
    data_agendamento TIMESTAMP NOT NULL,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Agendada',

    FOREIGN KEY (id_jogador)
        REFERENCES jogadores(id_jogador),

    FOREIGN KEY (id_modalidade)
        REFERENCES modalidades(id_modalidade),

    CHECK (status IN ('Agendada', 'Em andamento', 'Concluida', 'Cancelada'))
);



CREATE TABLE historico_partidas (
    id_historico SERIAL PRIMARY KEY,
    id_partida INTEGER NOT NULL,
    descricao TEXT NOT NULL,
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_partida)
        REFERENCES partidas(id_partida)
);



INSERT INTO jogadores (nickname, email, senha, ativo) VALUES
('GaiaX', 'gaia@email.com', '123456', TRUE),
('Lorenzo', 'lorenzo@email.com', '123456', TRUE),
('EmaPlay', 'ema@email.com', '123456', TRUE),
('Banido', 'banido@email.com', '123456', FALSE);



INSERT INTO modalidades (nome, categoria) VALUES
('League of Legends', 'MOBA'),
('Valorant', 'FPS'),
('Rocket League', 'Esporte');



CREATE OR REPLACE FUNCTION fn_buscar_jogadores(termo TEXT)
RETURNS TABLE (
    nickname VARCHAR,
    email VARCHAR
)
LANGUAGE SQL
AS $$
    SELECT j.nickname, j.email
    FROM jogadores j
    WHERE j.nickname ILIKE '%' || termo || '%'
       OR j.email ILIKE '%' || termo || '%';
$$;



CREATE OR REPLACE FUNCTION fn_validar_partida()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    jogador_ativo BOOLEAN;
BEGIN
    SELECT ativo INTO jogador_ativo
    FROM jogadores
    WHERE id_jogador = NEW.id_jogador;

    IF jogador_ativo IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'Jogador inexistente ou inativo!';
    END IF;

    NEW.data_criacao = CURRENT_TIMESTAMP;

    RETURN NEW;
END;
$$;



CREATE TRIGGER trg_validar_partida
BEFORE INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_validar_partida();



CREATE OR REPLACE FUNCTION fn_historico()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO historico_partidas
    (id_partida, descricao)
    VALUES
    (NEW.id_partida, 'Partida cadastrada');

    RETURN NEW;
END;
$$;



CREATE TRIGGER trg_historico
AFTER INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_historico();



INSERT INTO partidas
(titulo, id_jogador, id_modalidade, data_agendamento)
VALUES
('Campeonato LoL', 1, 1, CURRENT_TIMESTAMP + INTERVAL '2 days'),
('Final Valorant', 2, 2, CURRENT_TIMESTAMP + INTERVAL '5 days'),
('Torneio Rocket League', 3, 3, CURRENT_TIMESTAMP + INTERVAL '8 days');



CREATE VIEW vw_painel_principal AS
SELECT
    j.nickname,
    p.titulo,
    m.categoria,
    p.data_agendamento,
    p.status
FROM partidas p
JOIN jogadores j ON p.id_jogador = j.id_jogador
JOIN modalidades m ON p.id_modalidade = m.id_modalidade;



CREATE VIEW vw_cronograma_partidas AS
SELECT
    p.titulo,
    p.data_agendamento,
    p.status,
    p.data_agendamento::date - CURRENT_DATE AS dias_restantes,
    j.nickname
FROM partidas p
JOIN jogadores j ON p.id_jogador = j.id_jogador
ORDER BY p.data_agendamento;



SELECT * FROM jogadores;

SELECT * FROM modalidades;

SELECT * FROM partidas;

SELECT * FROM historico_partidas;

SELECT * FROM vw_painel_principal;

SELECT * FROM vw_cronograma_partidas;

SELECT * FROM fn_buscar_jogadores('Gaia');