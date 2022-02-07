DO $$ BEGIN
    PERFORM drop_functions();
    PERFORM drop_tables();
END $$;

CREATE TABLE hotel (
	numero integer NOT NULL,
	nome TEXT NOT NULL,
	CONSTRAINT hotel_pk PRIMARY KEY (numero));
	
CREATE TABLE reserva (
	numero integer NOT NULL,
	hotel integer NOT NULL,
	cpf_cnpj integer NOT NULL,
	inicio timestamp not null,
	fim timestamp not null,
	CONSTRAINT reserva_pk PRIMARY KEY (numero),
	CONSTRAINT reserva_hotel_fk FOREIGN KEY (hotel) REFERENCES hotel (numero));
	
CREATE TABLE estadia (
	numero integer NOT NULL,
	quarto text not null,
	inicio timestamp not null,
	fim timestamp,
	CONSTRAINT estadia_pk PRIMARY KEY (numero),
	CONSTRAINT estadia_reserva_fk FOREIGN KEY (numero) REFERENCES reserva (numero)
 on delete restrict on update cascade);


-- para inserir estadia, precisa ter reserva
-- estadia deve ocorrer no intervalo da reserva
-- inicio da estadia tem que coincidir com inicio da reserva
CREATE OR REPLACE FUNCTION verificaReserva() RETURNS TRIGGER AS $$
DECLARE
BEGIN

    IF NOT EXISTS (SELECT * FROM reserva WHERE
                    reserva.numero = NEW.numero AND
                    ((NEW.inicio BETWEEN reserva.inicio AND reserva.fim) AND
                     (NEW.fim BETWEEN reserva.inicio AND reserva.fim)) AND
                    (NEW.inicio::date = reserva.inicio::date)
                  ) THEN
        raise exception 'Não há reserva para essa estadia.';
    END IF;
    return NEW;

END
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_verificaReserva
BEFORE INSERT OR UPDATE ON estadia FOR EACH ROW
EXECUTE PROCEDURE verificaReserva();

-----------------------------------------------------------------------------

-- Hotel
INSERT INTO hotel(numero, nome)	VALUES (0, 'Hotel Teste');

-- Reserva
INSERT INTO reserva(numero, hotel, cpf_cnpj, inicio, fim)
	VALUES (0, 0, 12345678900, '2022-02-07 00:00:00', '2022-02-17 00:00:00');

-----------------------------------------------------------------------------

-- Reserva perdeu a validade após o fim do primeiro dia
INSERT INTO estadia(numero, quarto, inicio, fim)
	VALUES (0, 0, '2022-02-08 00:00:00', '2022-02-17 00:00:00');

-- Início da estadia antecede início da reserva
INSERT INTO estadia(numero, quarto, inicio, fim)
	VALUES (0, 0, '2022-02-06 00:00:00', '2022-02-07 00:00:00');

-- Fim da estadia é posterior ao fim da reserva
INSERT INTO estadia(numero, quarto, inicio, fim)
	VALUES (0, 0, '2022-02-07 00:00:00', '2022-02-18 00:00:00');

-- Identificador de reserva inválido
INSERT INTO estadia(numero, quarto, inicio, fim)
	VALUES (1, 0, '2022-02-07 00:00:00', '2022-02-17 00:00:00');

-- Estadia válida
INSERT INTO estadia(numero, quarto, inicio, fim)
	VALUES (0, 0, '2022-02-07 00:00:00', '2022-02-15 00:00:00');