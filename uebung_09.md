# Tutorium - Grundlagen Datenbanken - Blatt 9

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
Wo liegen die Vor- und Nachteile eines Trigger in Vergleich zu einer Prozedur?

#### Lösung
**Vorteile**
+ Ein Trigger löst automatisch vor oder nach einem Event/Vorfall aus. Er muss nicht explizit gestartet werden.
+ Kein Benutzer kann einen Trigger umgehen der aktiv ist.
+ Es müssen keine Berechtigungen für das Nutzen eines Trigger freigegeben werden

**Nachteile**
+ Kann keine Parameter übergeben bekommen
+ Kann keinen Rückgabewert liefern
+ Kann nur ausgeführt werden, wenn ein `INSERT`, `UPDATE` oder `DELETE` auf eine Tabelle ausgeführt wird. Eine Prozedur ist unabhängig.

### Aufgabe 2
Wo drin unterscheidet sich der `Row Level Trigger` von einem `Statement Trigger`?

#### Lösung
**Row Level Trigger**
Der Row Level Trigger wird immer dann ausgelöst, wenn eine Zeile durch den SQL-Befehl `INSERT`, `UPDATE` oder `DELETE` beinflusst wird. Wenn die Anweisung keine Zeilen trifft, wird keine Triggeraktion ausgefürt.

**Statement Trigger**
Diese Art von Trigger wird ausgelöst, wenn eine SQL-Anweisung die Zeilen der Tabellen betrifft. Wenn der Trigger aktiviert ist, führt er seine Aktivitäten unabhängig von der Anzahl der durch die SQL-Anweisung betroffenen Zeilen aus.

### Aufgabe 3
Schaue dir den folgenden PL/SQL-Code an. Was macht er?

```sql
CREATE SEQUENCE seq_account_id
START WITH 1000
INCREMENT BY 1
MAXVALUE 99999999
CYCLE
CACHE 20;

CREATE OR REPLACE TRIGGER BIU_ACCOUNT
BEFORE INSERT OR UPDATE OF account_id ON account
FOR EACH ROW
DECLARE

BEGIN
  IF UPDATING('account_id') THEN
    RAISE_APPLICATION_ERROR(-20001, 'Die Account-ID darf nicht verändert oder frei gewählt werden!');
  END IF;

  IF INSERTING THEN
    :NEW.account_id := seq_account_id.NEXTVAL;
  END IF;
END;
/
```

#### Lösung
Es wird eine Sequenz erzeugt auf die in dem Trigger `IB_ACCOUNT` zurückgegriffen wird. Das Kürzel `BIU` steht für `BEFORE`, `INSERT` und `UPDATE`. Es soll Kennzeichnen, dass der Trigger vor einem Einfügen oder Aktualisieren ausgefürt wird. Der Trigger bewirkt, dass bei einem Aktualisieren auf die Spalte `ACCOUNT_ID` der Tabelle `ACCOUNT` eine Fehlermeldung ausgegeben wird. Wird ein Datensatz neu eingefügt, wird der übergebene Wert für die Spalte `ACCOUNT_ID` durch ein Inkrement aus der Sequenz überschrieben. Dies stellt sicher, dass die Spalte `ACCOUNT_ID` ausschließlich aus einer fortlaufenden Nummer erzeugt wird.

### Aufgabe 4
Verbessere den Trigger aus Aufgabe 2 so, dass
+ wenn versucht wird einen Datensatz mit `NULL` Werten zu füllen, die alten Wert für alle Spalten, die als `NOT NULL` gekennzeichnet sind, behalten bleiben.
+ es nicht möglich ist, das die Werte für `C_DATE` und `U_DATE` in der Zukunkt liegen
+ `U_DATE` >= `C_DATE` sein muss
+ der erste Buchstabe jedes Wortes im Vor- und Nachnamen groß geschrieben wird
+ die Account-ID aus einer `SEQUENCE` entnommen wird

Nutze die Lösung der Aufgabe 2, Aufgabenblatt 8 um die Aufgabe zu lösen. Dort solltest du einige Hilfestellungen finden.

#### Lösung
```sql
-- Erstellen einer Sequenz
CREATE SEQUENCE seq_account_id
START WITH 1000                        -- Startwert der Sequenz
INCREMENT BY 1                         -- Intervall des Inkrements
MAXVALUE 99999999                      -- Maximaler Wert, die die Sequenz annehmen kann
CYCLE                                  -- Wird der Maximale Wert erreicht, fängt die Sequent bei START WITH wieder an
CACHE 20;                              -- Hält n Sequenzen im Cache

-- Erstellen des Triggers
CREATE OR REPLACE TRIGGER BIU_ACCOUNT
BEFORE INSERT OR UPDATE OF account_id ON account
FOR EACH ROW
DECLARE

BEGIN

  -- Überschreiben der Account-ID beim Einfügen durch ein Inkrement aus der Sequent seq_account_id
  IF INSERTING THEN
    :NEW.account_id := seq_account_id.NEXTVAL;
  END IF;

  -- Überschriben der Account-ID beim Aktualisieren durch die alte Account-ID
  -- Es ist dadurch nicht möglich die Account-ID zu ändern
  IF UPDATING('account_id') THEN
    :NEW.account_id := :OLD.account_id;
  END IF;

  -- Wenn SURNAME NULL ist, soll eine Fehlermeldung erscheinen bei einem INSERT-Befehl
  IF (INSERTING AND :NEW.surname IS NULL) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Der Nachname darf nicht NULL sein!');

  -- Wenn SURNAME NULL ist, soll bei einem UPDATE der alte Wert behalten bleiben
  ELSIF (UPDATING AND :NEW.surname IS NULL) THEN
    :NEW.surname := :OLD.surname;

  -- Ist SURNAME nicht NULL, soll der erste Buchstabe jedes Wortes im Nachnamen groß geschrieben werden
  ELSE
    :NEW.surname := INITCAP(:NEW.surname);
  END IF;

  -- Wenn FORENAME NULL ist, soll eine Fehlermeldung erscheiben bei einem INSERT-Befehl
  IF (INSERTING AND :NEW.forename IS NULL) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Der Vorname darf nicht NULL sein!');

  -- Wenn FORENAME NULL ist, soll bei einem UPDATE der alte Wert behalten bleiben
  ELSIF (UPDATEING AND :NEW.forename IS NULL) THEN
    :NEW.forename := :OLD.forename;

  -- Ist FORENAME nicht NULL, soll der erste Buchstabe jedes Wortes im Vornamen groß geschrieben werden
  ELSE
    :NEW.forename := INITCAP(:NEW.forename);
  END IF;

  -- Wenn EMAIL NULL ist, soll eine Fehlermeldung erscheinen bei einem INSERT-Befehl
  IF (INSERTING AND :NEW.email IS NULL) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Die E-MAIL darf nicht NULL sein!);

  -- Wenn EMAIL NULL ist, soll bei einem Update der alte Wert behalten bleiben
  ELSIF
    :NEW.email := :OLD.email;
  END IF;

  -- Wenn C_DATE NULL ist, wird SYSDATE verwendet
  IF (:NEW.C_DATE is NULL) THEN
    :NEW.C_DATE := SYSDATE;
  END IF;

  -- Wenn U_DATE NULL ist, wird SYSDATE verwendet
  IF (:NEW.U_DATE IS NULL) THEN
    :NEW.U_DATE := SYSDATE;
  END IF;

  -- Wenn das Erstellungsdatum jünger ist als das Aktualisierungsdatum soll abgebrochen werden
  IF (:NEW.C_DATE > :NEW.U_DATE) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Das U_DATE muss größer (jünger) als das C_DATE sein!');
  END IF;

END;
/

-- Testen des Triggers
INSERT INTO ACCOUNT (SURNAME, FORENAME, EMAIL)              -- Spalten die nicht angegeben werden, jedoch Pflichtfelder sind,
VALUES ('brückner', 'thorsten', 'bruecknert@fh-trier.de');  -- werden durch den Trigger mit Werten ersetzt. Dazu zählt die ID, das C_DATE und U_DATE.
```

### Aufgabe 5
Angenommen der Steuersatz in Deutschland sinkt von 19% auf 17%.
+ Aktualisiere den Steuersatz von Deutschland und
+ alle Quittungen die nach dem `01.10.2017` gespeichert wurden.

#### Lösung
```sql
-- Tabelle Country
UPDATE country
SET duty_amount = 0.17
WHERE country_name LIKE 'Deutschland';

-- Tabelle Receipt
UPDATE receipt r
SET r.duty_amount = (
  SELECT c.duty_amount
  FROM country c
    INNER JOIN gas_station gs ON (gs.country_id = c.country_id)
  WHERE gs.gas_station_id = r.gas_station_id
)
WHERE r.gas_station_id IN (
    SELECT gs.gas_station_id
    FROM gas_station gs
        INNER JOIN country c ON (gs.country_id = c.country_id)
    WHERE c.country_name LIKE 'Deutschland'
)
AND C_DATE >= TO_DATE('01.10.2017', 'DD.MM.YYYY');
```

### Aufgabe 6
Liste alle Hersteller auf, die LKW's produzieren und verknüpfe diese ggfl. mit den Eigentümern.

#### Lösung
```sql
SELECT vt.vehicle_type_name "Typ",
       p.producer_name "Hersteller",
       (CASE WHEN a.forename IS NULL AND a.surname IS NULL THEN NULL ELSE CONCAT(a.forename, CONCAT(' ', a.surname)) END)  "Besitzer"
FROM vehicle v
  INNER JOIN vehicle_type vt ON (v.vehicle_type_id = vt.vehicle_type_id)
  INNER JOIN producer p ON (v.producer_id = p.producer_id)
  LEFT JOIN acc_vehic accv ON(v.vehicle_id = accv.vehicle_id)
  LEFT JOIN account a ON (accv.account_id = a.account_id)
WHERE vt.vehicle_type_name LIKE 'LKW';
```


























