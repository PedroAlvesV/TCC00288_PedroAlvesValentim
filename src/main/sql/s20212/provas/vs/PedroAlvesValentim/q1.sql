DO $$ BEGIN
    PERFORM drop_functions();
    PERFORM drop_tables();
END $$;

CREATE OR REPLACE FUNCTION cofatora(matriz float[][], i int, j int) RETURNS float[][] as $$
DECLARE
    linesMat integer;
    columnsMat integer;
    line float[];
    matResult float[][];
BEGIN
    SELECT array_length(matriz, 1) INTO linesMat;
    SELECT array_length(matriz, 2)INTO columnsMat;
    matResult := array_fill(0, ARRAY[0,0]);
    FOR x IN 1..linesMat LOOP
        line := '{}';
        IF x <> i THEN
            FOR y IN 1..columnsMat LOOP
                IF y <> j THEN
                    line := array_append(line, matriz[x][y]);
                END IF;
            END LOOP;
            matResult := array_cat(matResult, ARRAY[line]);
        END IF;
    END LOOP;
    RETURN matResult;
END 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION determinante(mat float[][]) RETURNS float as $$
DECLARE
    x integer;
    columnsMat integer;
    det float;
BEGIN
    SELECT array_length(mat, 2)INTO columnsMat;
    x := 1;
    det := 0;

    IF columnsMat > 0 THEN
        FOR y IN 1..columnsMat LOOP
            IF ((x + y)%2 = 1) THEN
                det := det + (mat[x][y] * (-1) * determinante(cofatora(mat, x, y)));
            ELSE
                det := det + (mat[x][y] * determinante(cofatora(mat, x, y)));
            END IF;
        END LOOP;
    ELSE
        det := 1;
    END IF;
    RETURN det;
END 
$$ LANGUAGE plpgsql;

select determinante('{{4, 0}, {7, 3}}');