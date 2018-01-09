# Tutorium - Grundlagen Datenbanken - Blatt 13

## Vorbereitungen
* Für dieses Aufgabenblatt wird die SQL-Dump-Datei `schema_uebung_13.sql` benötigt, die sich im Verzeichnis `sql` befindet.
* Die SQL-Dump-Datei wird in SQL-Plus mittels `start <Dateipfad/zur/sql-dump-datei.sql>` in die Datenbank importiert.
* Beispiele
  * Linux `start ~/Tutorium.sql`
  * Windows `start C:\Users\max.mustermann\Desktop\Tutorium.sql`

## Datenbankmodell
Gegeben sei folgender Situation:
+ Ein Kunde kann eine oder mehrere Bestellungen aufgeben
+ In einer Bestellung wird wenigstens ein eventuell mehrere Artikel (in einer gewissen Menge) bestellt.
+ Eine Lieferung kann sich auch auf mehrere Bestellpositionen des gleichen Kunden beziehen.
+ Eine Bestellposition muss nicht gleich von Anfang an mit einer Lieferung verknüpft werden (also der Artikel nicht gleich ausgeliefert werden).

Folgendes relationale Schema soll diesen Realitätsausschnitt abbilden:

![Databasemodell](./img/schema_uebung_13.png)

## Aufgaben
Führe das in Abschnitt Vorbereitung genannte Skript aus. Die untenstehenden Aufgaben beziehen sich auf das oben dargestellte relationale Schema.

### Aufgabe 1
Gebe mit einem regulären Ausdruck alle Artikel aus, die mit einem Großbuchstaben beginnen und mindestens 4 Zeichen lang sind.

#### Lösung
```sql
SELECT a.Bezeichnung
FROM artikel a
WHERE REGEXP_LIKE(a.Bezeichnung, '^[A-Z].{3,}$', 'c');
```

### Aufgabe 2
Gebe mit einem regulären Ausdruck alle Artikelnummern aus, die aus 3 Ziffern bestehen, mit 1 beginnen und anschließend keine 4 folgt.

#### Lösung
```sql
SELECT a.artikelnr
FROM artikel a
WHERE REGEXP_LIKE(a.artikelnr, '^1[0-35-9]{2}$');
```

### Aufgabe 3
Gebe alle Kunden mit der Anzahl ihrer Bestellungen aus. Hier sollen auch Kunden zurückgegeben werden, die bisher keine Bestellungen getätigt haben.

#### Lösung
```sql
SELECT p.name, COUNT(b.bestellnr) AS "anzahl"
FROM person p
LEFT JOIN bestellung b ON (b.pnr = p.pnr)
GROUP BY p.name
HAVING REGEXP_LIKE(COUNT(b.bestellnr), '^0');
```

### Aufgabe 4
Ergänzen Sie das Skript um das `CREATE TABLE` statement für die Tabelle `BESTELLPOSITION` mit den notwendigen `NOT NULL` Constraints.

#### Lösung
```sql
CREATE TABLE "BESTELLPOSITION" (
  "BESTELLNR"     NUMBER(38) NOT NULL PRIMARY KEY,
  "ARTIKELNR"     NUMBER(38) NOT NULL,
  "LIEFERUNGSNR"  NUMBER(38),
  "MENGE"         NUMBER(38) NOT NULL,
  CONSTRAINT "PK_BESTELLNR"·PRIMARY KEY (BESTELLNR, ARTIKELNR);
);
```

### Aufgabe 5
Stellen Sie sicher, dass eine Bestellnr immer größer null ist.

#### Lösung
```sql
ALTER TABLE bestellposition
ADD CONSTRAINT "C_BESTELLNR"
CHECK (
  bestellnr > 0
);
```

### Aufgabe 6
Ergänzen Sie das Skript um eine Definition eines geeigneten `PRIMARY KEY` für die Tabelle `Bestellposition` und der drei `FOREIGN KEY`s zu `LIEFERUNG`, `BESTELLUNG` und `ARTIKEL` mit den o.g. Namen.

#### Lösung
```sql
-- FOREIGN KEY
ALTER TABLE bestellposition
ADD CONSTRAINT "FK_BESTELLPOSITION_LIEFERUNG"
  FOREIGN KEY (lieferungsnr)
  REFERENCES lieferung(lieferungsnr);

ALTER TABLE bestellposition
ADD CONSTRAINT "FK_BESTELLPOSITION_BESTELLUNG"
  FOREIGN KEY (bestellnr)
  REFERENCES bestellung(bestellnr);

ALTER TABLE bestellposition
ADD CONSTRAINT "FK_BESTELLPOSITION_ARTIKEL"
  FOREIGN KEY (artikelnr)
  REFERENCES artikel(artikelnr);

-- PRIMARY KEY
-- Der Primary Key wurde bereits durch das CREATE TABLE Statement erzeugt. Kann aber auch manuell erzeugt werden.
ALTER TABLE bestellposition
ADD CONSTRAINT "PK_BESTELLNR"
  PRIMARY KEY (bestellnr, artikelnr);
```

### Aufgabe 7
Starten Sie das so veränderte Skript.

#### Lösung
```sql
-- Beispiel Linux und Mac
start '~/workspace/tgdb_ws1718/sql/schema.sql'

-- Beispiel Windows
start 'C:\Users\hugo\workspace\tgdb_ws1718\sql\schema.sql'
```

### Aufgabe 8
Stellen Sie sicher, dass jede Person, die neu in den Bestand aufgenommen wird eine pnr aus einer Sequence erhält und dass eine `PNR` später nicht mehr durch einen `UPDATE` verändert werden darf. Die Sequence soll `PERSON_SEQ` heißen und bei `1000` beginnen.

#### Lösung
```sql
-- Sequenz
CREATE SEQUENCE "PERSON_SEQ"
START WITH 1000
INCREMENT BY 1;

-- Trigger
CREATE OR REPLACE TRIGGER PersonNr_Sequence_Trigger
BEFORE INSERT OR UPDATE OF pnr ON Person
FOR EACH ROW
DECLARE

BEGIN
  IF UPDATING('pnr') THEN
    RAISE_APPLICATION_ERROR(-20001, 'Personennummer darf nicht verändert werden!');
  END IF;

  IF INSERTING THEN
    :NEW.pnr := person_seq.NEXTVAL;
  END IF;
END;
/
```

### Aufgabe 9
Erfassen Sie eine Bestellung, mit Bestellnr 100, dem Datum von heute und ordnen Sie es dem Kunden Hugo McKinnock zu.

Dieser Kunde bestellt den Artikel **SAP for beginners** mit der Artikelnummer `123` und dem Verkaufspreis 25 Euro zwei mal. Zusätzlich bestellt der Kunde den Artikel mit der Artikelnummer `234` ein mal.

#### Lösung
```sql
INSERT INTO Bestellung
VALUES (100, (SELECT pnr
              FROM person
              WHERE name LIKE 'Hugo McKinnock'),
        SYSDATE);

INSERT INTO Bestellposition
VALUES (100, 123, NULL, 2);

INSERT INTO Bestellposition
VALUES (100, 234, NULL, 1);
```

### Aufgabe 10
Räumen Sie dem DB-Benutzer `SCOTT` das Recht ein, `UPDATE` (nicht auf `ARTIKELNR`) und `SELECT` auf der Tabelle `ARTIKEL` durchführen zu können.

#### Lösung
```sql
GRANT UPDATE(bezeichnung, preis), SELECT
ON artikel
TO scott;
```

### Aufgabe 11
Löschen Sie alle Personen, deren letzte Bestellung vom heutigen Tag aus gesehen mehr als ein Jahr zurückliegt.

Vorsicht: Der Kunde könnte mehrere Bestellungen aufgegeben haben oder auch gar keine.

#### Lösung
```sql
DELETE FROM person
WHERE pnr IN (
  SELECT pnr
  FROM bestellung
  GROUP BY pnr
  HAVING MAX(datum) < SYSDATE - INTERVAL '1' YEAR
);
```

### Aufgabe 12
Geben Sie die Personen aus absteigend sortiert nach Namen und innerhalb des gleichen Namens aufsteigend nach Geburtsdatum.

#### Lösung
```sql
SELECT p.Name, p.Geburtsdatum
FROM person p
ORDER BY p.Name DESC, p.Geburtsdatum ASC;
```

### Aufgabe 13
Erhöhen Sie den Preis jeden Artikels um 5%.

#### Lösung
```sql
UPDATE artikel
SET preis = preis * 1.05;
```

### Aufgabe 14
Für welche der Bestellungen ist noch keine Lieferung erfolgt?

#### Lösung
```sql
SELECT DISTINCT(b.Bestellnr)
FROM Bestellung b
  INNER JOIN bestellposition bp ON (bp.bestellnr = b.bestellnr)
WHERE bp.lieferungsnr IS NULL;
```

### Aufgabe 15
Geben Sie die Personen aus, die mindestens 18 Jahre alt sind.

#### Lösung
```sql
SELECT p.Name
FROM person p
WHERE p.GEBURTSDATUM < (sysdate - INTERVAL '18' YEAR);
```

### Aufgabe 16
Geben Sie alle Personen aus, deren Namen zwischen fünf und zehn Zeichen lang sind und einen Bindestrich (-) enthalten.

#### Lösung
```sql
SELECT p.Name
FROM Person p
WHERE LENGTH(p.Name) > 4
AND LENGTH(p.Name) < 11
AND p.Name LIKE '%-%';
```
