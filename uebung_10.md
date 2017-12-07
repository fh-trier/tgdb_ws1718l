# Tutorium - Grundlagen Datenbanken - Blatt 10

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
Was macht der folgende SQL-Code?

```sql
WITH vehicles AS (
    SELECT COUNT(*) Anzahl, accv.account_id
    FROM acc_vehic accv
    GROUP BY accv.account_id
)
SELECT CONCAT(a.forename, CONCAT(' ', a.surname)) AS "Benutzer" , v.Anzahl AS "Anzahl"
FROM vehicles v
    INNER JOIN account a ON (v.account_id = a.account_id)
WHERE v.Anzahl = (
    SELECT MAX(Anzahl)
    FROM vehicles
);
```

#### Lösung
Es wird ein SQL-Statement durch eine `WITH` Klausel zwischengespeichert unter dem Namen `vehicles`. In der unteren Abfrage wird in dem `FROM` Bezug auf das zwischengespeicherte Ergebiss genommen.

### Aufgabe 2
Die folgende Aufgabe bezieht sich auf das Datenbankmodell der Vorlesung.
Geben Sie mit einem SQL Befehl alle Klausuren aus, zu denen sich Personen angemeldet haben, aber bei **ALLEN** angemeldeten Personen fehlt die Note.

#### Lösung
```sql
-- Mit Exists
SELECT KlausurNr
FROM Anmeldung a
WHERE	NOT EXISTS (
  SELECT *
  FROM Anmeldung
  WHERE a.KlausurNr = KlausurNr
  AND Note IS NOT NULL
);

-- Mit Subquerys
SELECT a1.KlausurNr
FROM Anmeldung a1
WHERE ( ( SELECT COUNT (*) AS "A_G"
          FROM Anmeldung a2
          WHERE a2.KlausurNr = a1.KlausurNr
        ) -
        ( SELECT COUNT (*) AS "A_B"
          FROM Anmeldung a3
          WHERE a3.KlausurNr = a1.KlausurNr
          AND a3.Note IS NOT NULL
        )
      ) = ( SELECT COUNT (*) AS "A_G"
            FROM Anmeldung a4
            WHERE a4.KlausurNr = a1.KlausurNr)
ORDER BY a1.KlausurNr ASC;
```

### Aufgabe 3
Finde mit der Option `EXISTS` herraus, wie viele Hersteller in der Datenbank hinterlegt sind ohne mit einem Auto verknüpft zu sein.

#### Lösung
```sql
SELECT COUNT(producer_id) AS Anzahl
FROM producer p
WHERE NOT EXISTS (
    SELECT producer_id
    FROM vehicle v
    WHERE v.producer_id = p.producer_id
);
```
