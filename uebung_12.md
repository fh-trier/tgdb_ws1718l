# Tutorium - Grundlagen Datenbanken - Blatt 12


## Vorbereitungen
* Für dieses Aufgabenblatt wird die SQL-Dump-Datei `schema_uebung_12.sql` benötigt, die sich im Verzeichnis `sql` befindet.
* Die SQL-Dump-Datei wird in SQL-Plus mittels `start <Dateipfad/zur/sql-dump-datei.sql>` in die Datenbank importiert.
* Beispiele
  * Linux `start ~/Tutorium.sql`
  * Windows `start C:\Users\max.mustermann\Desktop\Tutorium.sql`

## Datenbankmodell
![Datenbankmodell](./img/schema_uebung_12.png)

## Aufgaben
Diese Aufgaben lehnen sich an eine Altklausur an. Jede Aufgabe gibt 5 Punkte. 1 Punkt entspricht einer Bearbeitungszeit von 1 Minute. Bei 13 Aufgaben entspricht das 65 Minuten. Versuchen Sie die 13 Aufgaben binnen 65 Minuten zu lösen.

### Aufgabe 1
Sie haben ein `SELECT`-Recht auf die Tabelle `ARTIKEL` im Schema `peschm` - Warum?

#### Lösung
```sql
SELECT table_name, privilege, grantee
FROM all_tab_privs
WHERE REGEXP_LIKE(table_name, 'artikel', 'i')
AND REGEXP_LIKE(table_schema, 'peschm', 'i')
AND grantee IN (
  USER,
  (SELECT granted_role
  FROM user_role_privs),
  'PUBLIC'
);
```

### Aufgabe 2
Legen Sie ein Synonym mit Namen `ARTIKEL` für die Tabelle an aus Aufgabe 1 und bestimmen Sie die Anzahl der Artikel in dieser Tabelle.

#### Lösung
```sql
-- Synonym
CREATE SYNONYM artikel
FOR peschm.artikel;

-- Anzahl der Artikel in der Tabelle
SELECT COUNT(a.artikelnr)
FROM artikel a
```

### Aufgabe 3a
Ergänzen Sie das Skript um ein geeignetes `CREATE TABLE` Statement für die Tabelle `BESTELLUNG`, das zur obigen Grafik passt, einschließlich `PRIMARY KEY`. Die `FOREIGN KEYS`  werden in Aufgabe 3b angelegt. Starten Sie anschließend das Skript.

#### Lösung
```sql
-- Am Ende des Sktipts wird folgendes eingefügt
-- CREATE TABLE
CREATE TABLE bestellung (
  bestellnr     NUMBER(10)  NOT NULL,
  kundennr      NUMBER(10)  NOT NULL,
  bestelldatum  DATE        NOT NULL,
  lieferdatum   DATE,
  CONSTRAINT PK_BESTELLNR PRIMARY KEY (bestellnr)
);
```

### Aufgabe 3b
Implementieren Sie alle Foreign key Konstrukte, die in der obigen Grafik dargestellt sind mit geeigneten delete rules.

#### Lösung
```sql
-- FOREIGN KEYs
ALTER TABLE bestellung
ADD CONSTRAINT FK_BESTELLUNG_KUNDE
  FOREIGN KEY (kundennr)
  REFERENCES kunde(kundennr)
  ON DELETE CASCADE;

ALTER TABLE bestell_position
ADD CONSTRAINT FK_BESTELLPOS_BESTELLUNG
  FOREIGN KEY (bestellnr)
  REFERENCES bestellung(bestellnr)
  ON DELETE CASCADE;
```

### Aufgabe 4
Überprüfen Sie mit einem SQL Statement, ob alle Artikelnr in `BESTELL_POSITION` in der Tabelle DWH.ARTIKEL vorkommen.

#### Lösung
```sql
-- Abfrage
SELECT DISTINCT artikelnr
FROM bestell_position
WHERE artikelnr NOT IN (
  SELECT artikelnr
  FROM artikel
);

-- Kommentar
-- Ist die Ausgabe leer, werden alle Artikel in Bestell_Position in Artikel gelistet.
-- Sollte die Ausgabe eine Artikelnr zurückgeben, wird dieser Artikel nicht in der Artikel Tabelle geführt.
```

### Aufgabe 5
Stellen Sie sicher, dass das Attribut `MENGE` in der Tabelle `BESTELL_POSITION` nur positive Zahlen kleiner als `10` enthalten kann.

#### Lösung
```sql
ALTER TABLE bestell_position
ADD CONSTRAINT CHECK_MENGE
  CHECK (menge > 0 AND menge < 10);
```

### Aufgabe 6
Schreiben Sie eine `STORED PROCEDURE` mit geeigneter Fehlerbehandlung, die als Parameter eine Bestellnummer erwartet und den Gesamtwert über alle Bestellpositionen der Bestellung ausgibt. Die Einzelpreise befinden sich in der Tabelle `PESCHM.ARTIKEL` oder ihrem zuvor angelegtem Synonym.

#### Lösung
```sql
-- Servermitteilungen in SQL-Plus aktivieren
SET SERVEROUTPUT ON;

-- Stored Procedure
CREATE OR REPLACE PROCEDURE get_Gesamt(bestellnr_in IN NUMBER)
AS
  v_gesamtpreis artikel.einzelpreis%TYPE;
BEGIN
  SELECT SUM(a.einzelpreis * bp.menge) INTO v_gesamtpreis
  FROM bestell_position bp
    INNER JOIN artikel a ON (a.artikelnr = bp.artikelnr)
  WHERE bp.bestellnr = bestellnr_in;

  IF (v_gesamtpreis IS NULL) THEN
    DBMS_OUTPUT.PUT_LINE('Es wurden keine Bestellung mit der Nr ' || bestellnr_in || ' gefunden!');
  END IF;

  DBMS_OUTPUT.PUT_LINE('Gesamtpreis: ' || v_gesamtpreis);
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20002,'Irgend ein ander Fehler '|| substr(SQLERRM,1,80));
END;
/

-- Testen per BestellNr
EXEC get_Gesamt(83);
```

### Aufgabe 7
Stellen Sie sicher, dass eine neue Bestellung in die Tabelle `BESTELLUNG` nur eingetragen werden kann, indem automatisch der nächste Wert aus einer Sequence `BESTELLUNG_SEQ` als `BESTELLNR` genommen wird, die Sie auch noch anlegen müssen mit Startwert `30000` und increment `10`!

#### Lösung
```sql
-- Sequenz
CREATE SEQUENCE bestellung_seq
START WITH 30000
INCREMENT BY 10;

-- Trigger
CREATE OR REPLACE TRIGGER bestellung_BIU
BEFORE INSERT OR UPDATE OF bestellnr ON bestellung
FOR EACH ROW
DECLARE

BEGIN
  IF(INSERTING) THEN
    :NEW.bestellnr := bestellung_seq.NEXTVAL;
  END IF;

  IF(UPDATING('bestellnr')) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Bestellnr darf nicht verändert werden!');
  END IF;
END;
/
```

### Aufgabe 8
Beantworten Sie die folgenden Aufgaben mit einem SQL-Befehl:

#### Aufgabe 8a
Geben Sie alle Kunden aus mit der Anzahl ihrer Bestellungen!

##### Lösung
```sql
SELECT k.kundennr, COUNT(b.bestellnr)
FROM kunde k
  LEFT JOIN bestellung b ON (b.kundennr = k.kundennr)
GROUP BY k.kundennr;
```

#### Aufgabe 8b
Tragen Sie in der Bestellung mit Nr `19366` ein Lieferdatum ein, das neun Tage in der Zukunft liegt von heute aus gesehen!

##### Lösung
```sql
-- Änderung
UPDATE bestellung
SET lieferdatum = (SYSDATE + INTERVAL '9' DAY)
WHERE bestellnr = 19366;

-- Test
SELECT *
FROM bestellung
WHERE bestellnr = 19366;
```

#### Aufgabe 8c
Welcher Kunde hat am meisten Bestellungen aufgegeben?

##### Lösung
```sql
SELECT k.kundennr, COUNT(b.bestellnr)
FROM kunde k
  LEFT JOIN bestellung b ON (b.kundennr = k.kundennr)
GROUP BY k.kundennr
HAVING COUNT(b.bestellnr) = (
  SELECT MAX(COUNT(b2.bestellnr))
  FROM kunde k2
    LEFT JOIN Bestellung b2 ON (b2.kundennr = k2.kundennr)
  GROUP BY k2.kundennr
);

-- Kommentar:
-- Gibt nicht nur einen Kunden aus. Es werden alle Kunden ausgegeben, die das Maximum an Bestellungen aufgegeben haben.
```

#### Aufgabe 8d
Geben Sie Kunden aus, die keine Bestellung aufgegeben haben!

##### Lösung
```sql
SELECT k.name
FROM kunde k
WHERE k.kundennr NOT IN (
  SELECT kundennr
  FROM bestellung
);
```

#### Aufgabe 8e
Welcher Kunde hat den größten Bestellwert generiert?

##### Lösung
```sql
SELECT k.kundennr, k.name
FROM kunde k
WHERE k.kundennr IN (
  SELECT b.kundennr
  FROM bestellung b
    INNER JOIN bestell_position bp ON (bp.bestellnr = b.bestellnr)
    INNER JOIN ARTIKEL a ON (bp.artikelnr = a.artikelnr)
  HAVING SUM(bp.menge * a.einzelpreis) = (
    SELECT MAX(SUM(bp.menge * a.einzelpreis))
    FROM bestellung b
      INNER JOIN bestell_position bp ON (bp.bestellnr = b.bestellnr)
      INNER JOIN ARTIKEL a ON (bp.artikelnr = a.artikelnr)
    GROUP BY b.bestellnr
  )
  GROUP BY b.kundennr, b.bestellnr
);
```

