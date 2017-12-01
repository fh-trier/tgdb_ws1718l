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
+
+
+

**Nachteile**
+
+
+

### Aufgabe 2
Wo drin unterscheidet sich der `Row Level Trigger` von einem `Statement Trigger`?

#### Lösung
Deine Lösung

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
-- Erzeugen einer Sequenz für die Spalte Account_ID der Tabelle Account
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

  -- Wenn SURNAME NULL ist, soll der alte Wert für Surname übernommen werden
  IF (:NEW.surname IS NULL) THEN
    :NEW.surname := :OLD.surname;

  -- Ist SURNAME nicht NULL, soll der erste Buchstabe jedes Wortes im Nachnamen groß geschrieben werden
  ELSE
    :NEW.surname := INITCAP(:NEW.surname)
  END IF;

  -- Wenn FORENAME NULL ist, soll der alte Wert für FORENAME übernommen werden
  IF (:NEW.forename IS NULL) THEN
    :NEW.forename := :OLD.forename;

  -- Ist FORENAME nicht NULL, soll der erste Buchstabe jedes Wortes im Vornamen groß geschrieben werden
  ELSE
    :NEW.forename := INITCAP(:NEW.forename)
  END IF;

  -- Wenn EMAIL NULL ist, soll der alte Wert für EMAIL übernommen werden
  IF (:NEW.email IS NULL) THEN
    :NEW.email := :OLD.email;
  END IF;

  -- Wenn C_DATE NULL ist, wird SYSDATE verwendet
  IF (:NEW.C_DATE is NULL) THEN
    :NEW.C_DATE := SYSDATE;
  END IF;

  -- Wenn U_DATE NULL ist, wird SYSDATE verwendet
  IF (:NEW.U_DATE IS NULL) THEN
    :NEW.U_DATE := SYSDATE)
  ELSE IF;

  -- Wenn das Erstellungsdatum jünger ist als das Aktualisierungsdatum soll abgebrochen werden
  IF (:NEW.C_DATE > :NEW.U_DATE) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Das U_DATE muss größer (jünger) als das C_DATE sein!');
  END IF;

END;
/

```

### Aufgabe 5
Angenommen der Steuersatz in Deutschland sinkt von 19% auf 17%.
+ Aktualisiere den Steuersatz von Deutschland und
+ alle Quittungen die nach dem `01.10.2017` gespeichert wurden.

#### Lösung
```sql
Deine Lösung
```

### Aufgabe 6
Liste alle Hersteller auf, die LKW's produzieren und verknüpfe diese ggfl. mit den Eigentümern.

#### Lösung
```sql
Deine Lösung
```


























