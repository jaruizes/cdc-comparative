DECLARE
    v_counter NUMBER := 0;
    new_salario NUMBER := 0;
BEGIN
    FOR i IN 1..600000 LOOP
        new_salario := TRUNC(DBMS_RANDOM.VALUE(20000, 100000));
        UPDATE ADMIN.TABLA_DBZ_K8S SET SALARIO = new_salario WHERE id = i;
        UPDATE ADMIN.TABLA_DMS SET SALARIO = new_salario WHERE id = i;

        v_counter := v_counter + 1;

        -- Commit every 10,000 records to avoid running out of undo space
        IF MOD(v_counter, 20000) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
    COMMIT;
END;
/
