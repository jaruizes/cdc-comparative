DROP TABLE IF EXISTS TABLA_DMS;
DROP TABLE IF EXISTS TABLA_DBZ_ALONE;
DROP TABLE IF EXISTS TABLA_DBZ_K8S;

CREATE TABLE TABLA_DMS
(
    id                 NUMBER PRIMARY KEY,
    nombre             VARCHAR2(100),
    apellido           VARCHAR2(100),
    direccion          VARCHAR2(200),
    ciudad             VARCHAR2(100),
    codigo_postal      VARCHAR2(20),
    telefono           VARCHAR2(20),
    email              VARCHAR2(100),
    fecha_nacimiento   DATE,
    salario            NUMBER(10, 2),
    departamento_id    NUMBER,
    puesto             VARCHAR2(50),
    fecha_contratacion DATE,
    estado_civil       VARCHAR2(20),
    numero_hijos       NUMBER
);

CREATE TABLE TABLA_DBZ_ALONE
(
    id                 NUMBER PRIMARY KEY,
    nombre             VARCHAR2(100),
    apellido           VARCHAR2(100),
    direccion          VARCHAR2(200),
    ciudad             VARCHAR2(100),
    codigo_postal      VARCHAR2(20),
    telefono           VARCHAR2(20),
    email              VARCHAR2(100),
    fecha_nacimiento   DATE,
    salario            NUMBER(10, 2),
    departamento_id    NUMBER,
    puesto             VARCHAR2(50),
    fecha_contratacion DATE,
    estado_civil       VARCHAR2(20),
    numero_hijos       NUMBER
);

CREATE TABLE TABLA_DBZ_K8S
(
    id                 NUMBER PRIMARY KEY,
    nombre             VARCHAR2(100),
    apellido           VARCHAR2(100),
    direccion          VARCHAR2(200),
    ciudad             VARCHAR2(100),
    codigo_postal      VARCHAR2(20),
    telefono           VARCHAR2(20),
    email              VARCHAR2(100),
    fecha_nacimiento   DATE,
    salario            NUMBER(10, 2),
    departamento_id    NUMBER,
    puesto             VARCHAR2(50),
    fecha_contratacion DATE,
    estado_civil       VARCHAR2(20),
    numero_hijos       NUMBER
);

DECLARE
    v_counter NUMBER := 0;
    nombre VARCHAR2(10) := '';
    apellido VARCHAR2(10) := '';
    direccion VARCHAR2(20) := '';
    ciudad VARCHAR2(10) := '';
    codigo_postal VARCHAR2(5) := '';
    telefono VARCHAR2(10) := '';
    email VARCHAR2(50) := '';
    fecha_nacimiento DATE;
    salario NUMBER := 0;
    departamento_id NUMBER;
    puesto VARCHAR2(15) := '';
    fecha_contratacion DATE;
    estado_civil VARCHAR2(10) := '';
    numero_hijos NUMBER := 0;
BEGIN
    FOR i IN 1..600000 LOOP
        nombre := DBMS_RANDOM.STRING('U', 10); -- Genera un nombre aleatorio de 10 caracteres
        apellido := DBMS_RANDOM.STRING('U', 10); -- Genera un apellido aleatorio de 10 caracteres
        direccion := DBMS_RANDOM.STRING('U', 20); -- Genera una dirección aleatoria de 20 caracteres
        ciudad := DBMS_RANDOM.STRING('U', 10); -- Genera una ciudad aleatoria de 10 caracteres
        codigo_postal := LPAD(TRUNC(DBMS_RANDOM.VALUE(10000, 99999)), 5, '0'); -- Genera un código postal aleatorio de 5 dígitos
        telefono := LPAD(TRUNC(DBMS_RANDOM.VALUE(1000000000, 9999999999)), 10, '0'); -- Genera un teléfono aleatorio de 10 dígitos
        email := DBMS_RANDOM.STRING('U', 10) || '@example.com'; -- Genera un email aleatorio
        fecha_nacimiento := TO_DATE('01-JAN-1950','DD-MON-YYYY') + TRUNC(DBMS_RANDOM.VALUE(0, 25550)); -- Genera una fecha de nacimiento aleatoria
        salario := TRUNC(DBMS_RANDOM.VALUE(20000, 100000)); -- Genera un salario aleatorio entre 20,000 y 100,000
        departamento_id := TRUNC(DBMS_RANDOM.VALUE(1, 100)); -- Genera un ID de departamento aleatorio entre 1 y 100
        puesto := DBMS_RANDOM.STRING('U', 15); -- Genera un puesto aleatorio de 15 caracteres
        fecha_contratacion := TO_DATE('01-JAN-2000','DD-MON-YYYY') + TRUNC(DBMS_RANDOM.VALUE(0, 7300)); -- Genera una fecha de contratación aleatoria
        estado_civil := CASE TRUNC(DBMS_RANDOM.VALUE(1, 4))
            WHEN 1 THEN 'Soltero'
            WHEN 2 THEN 'Casado'
            WHEN 3 THEN 'Divorciado'
        END; -- Genera un estado civil aleatorio
        numero_hijos := TRUNC(DBMS_RANDOM.VALUE(0, 5)); -- Genera un número de hijos aleatorio entre 0 y 4

        INSERT INTO TABLA_DMS (
            id, nombre, apellido, direccion, ciudad, codigo_postal, telefono, email,
            fecha_nacimiento, salario, departamento_id, puesto,
            fecha_contratacion, estado_civil, numero_hijos
        ) VALUES (
            i, nombre, apellido, direccion, ciudad, codigo_postal, telefono, email, fecha_nacimiento, salario, departamento_id, puesto, fecha_contratacion, estado_civil, numero_hijos
        );

        INSERT INTO TABLA_DBZ_ALONE (
            id, nombre, apellido, direccion, ciudad, codigo_postal, telefono, email,
            fecha_nacimiento, salario, departamento_id, puesto,
            fecha_contratacion, estado_civil, numero_hijos
        ) VALUES (
             i, nombre, apellido, direccion, ciudad, codigo_postal, telefono, email, fecha_nacimiento, salario, departamento_id, puesto, fecha_contratacion, estado_civil, numero_hijos
        );

        INSERT INTO TABLA_DBZ_K8S (
            id, nombre, apellido, direccion, ciudad, codigo_postal, telefono, email,
            fecha_nacimiento, salario, departamento_id, puesto,
            fecha_contratacion, estado_civil, numero_hijos
        ) VALUES (
             i, nombre, apellido, direccion, ciudad, codigo_postal, telefono, email, fecha_nacimiento, salario, departamento_id, puesto, fecha_contratacion, estado_civil, numero_hijos
        );

        v_counter := v_counter + 1;

        -- Commit every 10,000 records to avoid running out of undo space
        IF MOD(v_counter, 10000) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
    COMMIT;
END;
/
