# Tutorium - Grundlagen Datenbanken - Blatt 3

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
Erstelle eine `INNER JOIN` (optional `WHERE`) Abfrage um die Beziehungen zwischen den Tabellen `GAS_STATION`, `Provider`, `COUNTRY` und `ADDRESS` aufzulösen, sodass eine ähnliche Ausgabe erstellt wird wie abgebildet.

| Anbieter  | Straße            | PLZ   | Ort         | Land        | Steuer  |
| --------- | ----------------- | ----- | ----------- | ----------- | ------- |
| Shell     | Zurlaubener 1     | 54292 | Trier       | Deutschland | 0.19    |
| Esso      | Triererstraße 10  | 53937 | Hellenthal  | Deutschland | 0,19    |
| ...       | ...               | ...   | ...         | ...         | ...     |

#### Lösung
```sql
-- INNER JOIN
SELECT p.provider_name, gs.street, a.plz, a.city, c.country_name, c.duty_amount
FROM gas_station gs
  INNER JOIN provider p ON (p.provider_id = gs.provider_id)
  INNER JOIN country c ON (c.country_id = gs.country_id)
  INNER JOIN address a ON (a.address_ID = gs.address_ID);

-- WHERE
SELECT provider.provider_name, gas_station.street, address.plz, address.city, country.country_name, country.duty_amount
FROM address, country, gas_station, provider
WHERE gas_station.address_id = address.address_id
AND gas_station.provider_id = provider.provider_id
AND gas_station.country_id = country.country_id;
```

### Aufgabe 2
Suche alle Tankstellen raus, deren Straßenname an zweiter Stelle ein `U` haben (case-insensetive). Verändere dazu die Abfrage aus Aufgabe 1. Optional für Enthusiasten, suche mittels Regulärem Ausdruck.

#### Lösung
```sql
SELECT p.provider_name, gs.street, a.plz, a.city, c.country_name, c.duty_amount
FROM gas_station gs
 INNER JOIN provider p ON (p.provider_id = gs.provider_id)
 INNER JOIN country c ON (c.country_id = gs.country_id)
 INNER JOIN address a ON (a.address_ID = gs.address_ID)
WHERE (
  gs.street LIKE '_U%'
  OR gs.street LIKE '_u%'
);

-- Optional
SELECT p.provider_name, gs.street, a.plz, a.city, c.country_name, c.duty_amount
 FROM gas_station gs
 INNER JOIN provider p ON (p.provider_id = gs.provider_id)
 INNER JOIN country c ON (c.country_id = gs.country_id)
 INNER JOIN address a ON (a.address_ID = gs.address_ID)
WHERE REGEXP_LIKE(gs.street, '^[A-Za-z][Uu].*');
```

### Aufgabe 3
Suche alle Tankstellen raus, die sich in Trier befinden.

#### Lösung
```sql
SELECT p.provider_name, gs.street, a.plz, a.city, c.country_name, c.duty_amount
FROM gas_station gs
  INNER JOIN provider p ON (p.provider_id = gs.provider_id)
  INNER JOIN country c ON (c.country_id = gs.country_id)
  INNER JOIN address a ON (a.address_ID = gs.address_ID)
WHERE a.plz IN (
  SELECT plz
  FROM address
  WHERE city = 'Trier'
);
```

#### Aufgabe 4
Füge eine fiktive Tankstelle hinzu. Sie darf auf keine bestehenden Informationen basieren. Nutze möglichst wenige SQL-Befehle. Rufe fehlende Informationen möglichst direkt ab.

#### Lösung
```sql
-- Neues Land anlegen
INSERT INTO country (country_id, country_name, duty_amount)
VALUES (MAX(country_id) + 1, 'Niederlande', 0.2);

-- Neuen Anbieter anlegen
INSERT INTO provider (provider_id, provider_name)
VALUES(MAX(provider_id) + 1, 'Petrol');

-- Neue Addresse anlegen
INSERT INTO address (address_id, plz, city)
VALUES(MAX(address_id) + 1, '9999', 'Amsterdam');

-- Neue Tankstelle anlegen
INSERT INTO gas_station (gas_station_id, provider_id, country_id, address_id, street)
VALUES(
  MAX(gas_station_id) + 1,
  (
    SELECT provider_id
    FROM provider
    WHERE provider_name = 'Petrol'),
  ( SELECT country_id
    FROM country
    WHERE country_name = 'Niederlande'
  ),
  ( SELECT address_id
    FROM address
    WHERE plz=9999
    AND city='Amsterdam'
  ),
  'Am Hafen 1');
```

### Aufgabe 5
Erstelle eine INNER JOIN (optional `WHERE`) Abfrage um die Beziehung zwischen den Tabellen `ACCOUNT`, `VEHICLE`, `VEHICLE_TYPE`, `GAS` und `PRODUCER` aufzulösen und zeige die Spalten `FORNAME`, `SURNAME`, `VEHICLE_TYPE_NAME`, `VERSION`, `BUILD_YEAR`, `PRODUCER_NAME` und `GAS_NAME` an. Richte SQL-Plus so ein, dass möglicht jeder Datensatz nur eine Zeile belegt.

* COLUMN <SPALTENNAME> FORMAT a<Zeichenlänge>
* COLUMN <SPALTENNAME> FORMAT <Zahlenlänge, pro Länge eine 9>
* Beispiel für eine Spalte des Datentyps `VARCHAR2`: `COLUMN SURNAME FORMAT a16`
* Beispiel für eine Spalte des Datentyps `NUMERIC`: `COLUMN SOLD_KILOMETER 9999`

#### Lösung
```sql
SELECT a.forename, a.surname, vt.vehicle_type_name, v.version, v.build_year, p.producer_name, g.gas_name
FROM account a
  INNER JOIN acc_vehic accv ON (a.account_id = accv.account_id)
  INNER JOIN vehicle v ON (v.vehicle_id = accv.vehicle_id)
  INNER JOIN vehicle_type vt ON (v.vehicle_type_id = vt.vehicle_type_id)
  INNER JOIN producer p ON (v.producer_id = p.producer_id)
  LEFT JOIN gas g ON (v.default_gas_id = g.gas_id);
```

### Aufgabe 6
Welche Fahrzeuge wurden noch keinem Benutzer zugewiesen? Gebe über das Fahrzeug Informationen über den Typ, den Hersteller, das Modell, Baujahr und den Kraftstoff aus.

#### Lösung
```sql
Deine Lösung
```

### Aufgabe 7
Verknüpfe eines der Autos aus Aufgabe 6 mit deinem Benutzernamen. Verwende dazu möglichst wenige SQL-Statements.

#### Lösung
```
Deine Lösung
```

### Aufgabe 8
An welcher Tankstelle wurde noch nie getankt? Gebe zu den Tankstellen die Informationen über den Standort der Tankstellen aus.

#### Lösung
```sql
Deine Lösung
```

### Aufgabe 9
Liste alle Benutzer (Vorname und Nachname) mit Fahrzeug (Hersteller, Modell, Alias) auf, die noch nie einen Beleg hinzugefügt haben.

#### Lösung
```sql
Deine Lösung
```

### Aufgabe 10
Liste alle Benutzer auf, die mit einem Fahrzeug schonmal im Außland tanken waren.

#### Lösung
```sql
Deine Lösung
```

### Aufgabe 11
Wie viele Benutzer haben einen LKW registriert?

#### Lösung
```sql
Deine Lösung
```

### Aufgabe 12
Wie viele Benutzer haben einen PKW und einen LKW registriert?

#### Lösung
```sql
Deine Lösung
```

### Aufgabe 13
Führe den Patch `02_patch.sql`, der sich im Verzeichnis `sql` befindet, in deiner Datenbank aus. Wie lautet der Befehlt zum import?

#### Lösung
```sql
Deine Lösung
```

### Aufgabe 14
Aktualisiere den Steuersatz aller Belege auf den Steuersatz des Landes, indem die Kunden getankt haben.

#### Lösung
```sql
Deine Lösung
```


