DO $$ BEGIN
    PERFORM drop_functions();
    PERFORM drop_tables();
END $$;

CREATE TABLE Atividade(
    id INT,
    nome VARCHAR);

CREATE TABLE Artista(
    id INT,
    nome VARCHAR,
    atividade INT);

CREATE TABLE Arena(
    id INT,
    nome VARCHAR);

CREATE TABLE Concerto(
    id INT,
    artista INT,
    arena INT,
    inicio TIMESTAMP,
    fim TIMESTAMP);


INSERT INTO Atividade values (1, 'Show de Rock');
INSERT INTO Atividade values (2, 'Show de Bossa Nova');
INSERT INTO Atividade values (3, 'Apresentação circense');
INSERT INTO Artista values (1, 'Led Zeppelin', 1);
INSERT INTO Artista values (2, 'João Gilberto', 2);
INSERT INTO Artista values (3, 'Cirque du Soleil', 2);
INSERT INTO Arena values (1, 'Maracanã');
INSERT INTO Arena values (2, 'Canecão');
INSERT INTO Arena values (3, 'Vivo Rio');

CREATE OR REPLACE FUNCTION checkUnique() RETURNS TRIGGER AS $$
declare
begin
    
    IF EXISTS (SELECT * FROM Concerto
                WHERE concerto.id != new.id AND
                (concerto.arena = new.arena OR concerto.artista = new.artista) AND
                (concerto.inicio BETWEEN new.inicio AND new.fim or concerto.fim BETWEEN new.inicio and new.fim)) THEN
        raise exception 'Horários informados incompatíveis';
    END IF;

    return NEW;
end;
$$ language plpgsql;

CREATE TRIGGER checkUnique
AFTER INSERT OR UPDATE ON Concerto FOR EACH ROW
EXECUTE PROCEDURE checkUnique();

CREATE OR REPLACE FUNCTION auxFunction() RETURNS TRIGGER AS $$
declare
begin
    create temp table activityAux(id int) on commit drop;
    return null;
end;
$$ language plpgsql;

CREATE TRIGGER auxTrigger
BEFORE UPDATE OR DELETE ON Artista FOR EACH STATEMENT
EXECUTE PROCEDURE auxFunction();

CREATE OR REPLACE FUNCTION registerArtist() RETURNS TRIGGER AS $$
declare
begin
    INSERT INTO activityAux values(old.atividade);
    return null;
end;
$$ language plpgsql;

CREATE TRIGGER registerArtist
AFTER UPDATE OR DELETE ON Artista FOR EACH ROW
EXECUTE PROCEDURE registerArtist();

CREATE OR REPLACE FUNCTION checkActivity() RETURNS TRIGGER AS $$
declare
    counter int;
    atvd record;
begin
    
    FOR atvd in SELECT DISTINCT * FROM activityAux LOOP

        Select count(*) from Artista WHERE atividade = atvd.id INTO counter;
        IF counter = 0 THEN
            raise exception 'Atividade informada sem artista';
        END IF;

    END LOOP;

    return NULL;
end;
$$ language plpgsql;

CREATE TRIGGER checkActivity
AFTER UPDATE OR DELETE ON Artista FOR EACH STATEMENT
EXECUTE PROCEDURE checkActivity();

-- Problema da atividade vazia:
DELETE FROM Artista WHERE id = 1;

-- Problema da atividade vazia:
UPDATE Artista set atividade = 2 WHERE id = 1;

-- Arenas
INSERT INTO Concerto values (1, 1, 1, '2022-11-10 00:00:00', '2022-11-10 00:00:10');
INSERT INTO Concerto values (2, 1, 2, '2022-11-10 00:00:00', '2022-11-10 00:00:05');
INSERT INTO Concerto values (3, 1, 3, '2022-11-10 00:00:00', '2022-11-10 00:00:30');

-- Artistas
INSERT INTO Concerto values (1, 1, 1, '2022-11-10 00:00:00', '2022-11-10 00:00:10');
INSERT INTO Concerto values (2, 2, 1, '2022-11-10 00:00:00', '2022-11-10 00:00:05');
INSERT INTO Concerto values (3, 3, 1, '2022-11-10 00:00:00', '2022-11-10 00:00:30');

-- Horários
INSERT INTO Concerto values (1, 1, 1, '2022-11-10 00:00:00', '2022-11-10 00:00:10');
INSERT INTO Concerto values (2, 2, 1, '2022-10-10 00:00:00', '2022-10-10 00:00:05');
INSERT INTO Concerto values (3, 3, 1, '2022-11-10 00:00:00', '2022-11-10 00:00:30');