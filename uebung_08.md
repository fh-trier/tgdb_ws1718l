# Tutorium - Grundlagen Datenbanken - Blatt 8

## Vorbereitungen
* Für dieses Aufgabenblatt wird die SQL-Dump-Datei `schema_default.sql` benötigt, die sich im Verzeichnis `sql` befindet.
* Die SQL-Dump-Datei wird in SQL-Plus mittels `start <Dateipfad/zur/sql-dump-datei.sql>` in die Datenbank importiert.
* Beispiele
  * Linux `start ~/Tutorium.sql`
  * Windows `start C:\Users\max.mustermann\Desktop\Tutorium.sql`

## Datenbankmodell
![Datenbankmodell](./img/schema_default.png)

## Aufgaben

### Aufgabe 1
Erstelle eine Prozedur, die das anlegen von Benutzern durch übergabe von Parametern ermöglicht.

#### Lösung
```sql
CREATE OR REPLACE PROCEDURE I_ACCOUNT(in_surname IN VARCHAR2, in_forename IN VARCHAR2, in_email IN VARCHAR2)
AS

BEGIN
  INSERT INTO account
  VALUES (
    (SELECT MAX(account_id) + 1 FROM account),
    in_surname,
    in_forename,
    in_email,
    SYSDATE,
    SYSDATE
  );
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE ('Folgender unerwarteter Fehler ist aufgetreten: ');
    RAISE;
END;
/
```

Ausführen der Prozedur
```sql
exec I_ACCOUNT('Markus', 'Pesch', 'test@web.de');
```

### Aufgabe 2
Erstelle eine Prozedur, die das erstellen von Quittungen ermöglicht. Fange entsprechende übergebene Parameter auf `NULL` ab. Ergänze eventuell Parameter die `NULL` sind mit Informationen die sich durch Abfragen erklären lassen. Berücksichtige die Fehlerbehandlung!

#### Lösung
```sql
CREATE OR REPLACE PROCEDURE I_RECEIPT(
    in_email IN VARCHAR2,
    in_accv_id IN NUMBER,
    in_duty_amount IN NUMBER,
    in_gas_id IN NUMBER,
    in_gas_station_id IN NUMBER,
    in_price_l IN NUMBER,
    in_kilometer IN NUMBER,
    in_liter IN NUMBER,
    in_receipt_date IN DATE)
AS
    v_account_id account.account_id%TYPE;
    v_accv_id acc_vehic.acc_vehic_id%TYPE;
    v_gas_id gas.gas_id%TYPE;
    v_gas_station_id gas_station.gas_station_id%TYPE;
    v_duty_amount country.duty_amount%TYPE;
    v_receipt_date receipt.receipt_date%TYPE;
BEGIN
    -- Überprüfung Benutzer
    IF ( TRUE <> REGEXP_LIKE (in_email, '[a-zA-Z0-9._%-]+@[a-zA-Z0-9._%-]+\.[a-zA-Z]{2,7}')) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Die E-Mail entspricht nicht den Konditionen.');
    ELSE
        BEGIN
            SELECT account_id INTO v_account_id
            FROM account
            WHERE email = in_email;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20001, 'Es konnte kein Benutzer mit der E-Mail Adresse ' || in_email || ' gefunden werden!');
        END;
    END IF;

    -- Überprüfung Fahrzeug
    BEGIN
        SELECT acc_vehic_id INTO v_accv_id
        FROM acc_vehic
        WHERE acc_vehic_id = in_accv_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Es konnte kein Fahrzeug mit der ACC_VEHIC_ID ' || in_accv_id || ' gefunden werden!');
    END;

    -- Tankstellen ID
    BEGIN
        SELECT gas_station_id INTO v_gas_station_id
        FROM gas_station
        WHERE gas_station_id = in_gas_station_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Es konnte keine Tankstelle mit der GAS_STATION_ID ' || in_gas_station_id || ' gefunden werden!');
    END;

    -- Price/l
    IF (in_price_l IS NULL OR in_price_l = '') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Der Parameter in_price_l ist ungültig.');
    END IF;

    -- Liter
    IF (in_liter IS NULL OR in_liter = '') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Der Parameter in_liter ist ungültig.');
    END IF;

    -- Kilometer
    IF (in_kilometer IS NULL OR in_kilometer = '') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Der Parameter in_kilometer ist ungültig.');
    END IF;

    -- Receipt date
    IF (in_receipt_date IS NULL OR in_receipt_date = '') THEN
        v_receipt_date := SYSDATE;
    ELSE
        v_receipt_date := in_receipt_date;
    END IF;

    -- Gas
    IF (in_gas_id IS NULL OR in_gas_id = '') THEN
        BEGIN
            SELECT v.default_gas_id INTO v_gas_id
            FROM vehicle v
                INNER JOIN acc_vehic accv ON (accv.vehicle_id = v.vehicle_id)
            WHERE accv.acc_vehic_id = v_accv_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20001, 'Es konnte für das Fahrzeug kein Kraftstoff aus Bestandsdaten ermittelt werden!');
        END;
    ELSE
        v_gas_id := in_gas_id;
    END IF;

    -- Duty
    IF (in_duty_amount IS NULL OR in_duty_amount = '') THEN
        BEGIN
            SELECT c.duty_amount  INTO v_duty_amount
            FROM gas_station gs
                INNER JOIN country c ON (c.country_id = gs.country_id)
            WHERE gs.gas_station_id = v_gas_station_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20001, 'Es konnte kein Steuersatz für das Land indem die Tankstelle steht ermittelt werden!');
        END;
    ELSE
        v_duty_amount := in_duty_amount;
    END IF;

    BEGIN
        INSERT INTO RECEIPT
        VALUES(
            (SELECT MAX(receipt_id) + 1 FROM receipt),
            v_account_id,
            v_accv_id,
            v_duty_amount,
            v_gas_id,
            v_gas_station_id,
            in_price_l,
            in_kilometer,
            in_liter,
            v_receipt_date,
            SYSDATE,
            SYSDATE
        );
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001, 'Es konnte kein Datensatz eingefügt werden! - UNBEKANNTER GRUND');
    END;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE ('Folgender unerwarteter Fehler ist aufgetreten: ');
    RAISE;
END;
/
```

Ausführen der Prozedur
```sql
EXEC I_RECEIPT('peschm@fh-trier.de', 1, NULL, NULL, '1', '1,12', '478', '44,78', NULL);
```

### Aufgabe 3
Erstelle ein Prozedur, mit der man seine eigene Fahrzeuge in der Datenbank aktualisieren kann. Bspw. die Änderung von Fahrzeug informationen.

#### Lösung
```sql
Deine Lösung
```

