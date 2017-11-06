# Tutorium - Grundlagen Datenbanken - Blatt 6

## Vorbereitungen
* Für dieses Aufgabenblatt wird die SQL-Dump-Datei `schema_default.sql` benötigt, die sich im Verzeichnis `sql` befindet.
* Die SQL-Dump-Datei wird in SQL-Plus mittels `start <Dateipfad/zur/sql-dump-datei.sql>` in die Datenbank importiert.
* Beispiele
  * Linux `start ~/Tutorium.sql`
  * Windows `start C:\Users\max.mustermann\Desktop\Tutorium.sql`

## Datenbankmodell
![Datenbankmodell](./img/schema_default.png)

## Data-Dictionary-Views
![Data-Dictionary-Views](./img/constraint_schema.png)

## Aufgaben

### Aufgabe 1
Wie heißt der Primary Key Contraint der Tabelle `VEHICLE` und für welche Spalten wurde er angelegt?

#### Lösung
```sql
SELECT ucc.constraint_name, ucc.column_name, ucc.position
FROM user_cons_columns ucc
WHERE ucc.constraint_name = (
  SELECT uc.constraint_name
  FROM user_constraints uc
  WHERE uc.table_name LIKE 'VEHICLE'
  AND uc.constraint_type LIKE 'P'
);
```

### Aufgabe 2
Für welche Spalte**n** der Tabelle `ACC_VEHIC` wurde ein Foreign Key angelegt und auf welche Spalte/n in welcher Tabelle wird er referenziert?

#### Lösung
```sql
SELECT ucc.constraint_name, ucc.column_name, ucc.table_name
FROM user_cons_columns ucc
WHERE ucc.constraint_name IN (
  SELECT uc.constraint_name
  FROM user_constraints uc
  WHERE uc.table_name LIKE 'ACC_VEHIC'
  AND uc.constraint_type = 'R'
);
```

### Aufgabe 3
Erstelle einen Check Constraint für die Tabelle `ACCOUNT`, dass der Wert der Spalte `U_DATE` nicht älter sein kann als `C_DATE`.

#### Lösung
```sql
-- Check Constraint
ALTER TABLE account
ADD CONSTRAINT DATE_C
CHECK(
  U_DATE >= C_DATE
);

-- Test durch UPDATE
UPDATE account a
SET a.c_date = SYSDATE
WHERE a.account_id = (
    SELECT MIN(account_id)
    FROM account
);
```

### Aufgabe 4
Erstelle einen Check Constraint der überprüft, ob der erste Buchstabe der Spalte `GAS_NAME` der Tabelle `GAS` groß geschrieben ist.

#### Lösung
```sql
-- Check Constraint
ALTER TABLE gas
ADD CONSTRAINT UPPER_NAME_C
CHECK(
  REGEXP_LIKE(gas_name, '^[A-Z].*$', c)
);

-- Test durch Update
UPDATE gas g
SET gas_name = 'benzin 95'
WHERE gas_id = (
  SELECT MIN(gas_id)
  FROM gas
);
```

### Aufgabe 5
Erstelle einen Check Contraint der überprüft, ob der Wert der Spalte `IDENTICATOR` der Tabelle `ACC_VEHIC` eins von diesen möglichen Fahrzeugkennzeichenmustern entspricht. Nutze Reguläre Ausdrücke.

+ B:AB:5000
+ TR:MP:1
+ Y:123456
+ THW:98765
+ MZG:XZ:96

#### Lösung
```sql
-- Check Constraint
ALTER TABLE acc_vehic
ADD CONSTRAINT IDENTICATOR
CHECK(
  REGEXP_LIKE(identicator, '^[A-Z]{1,3}:([A-Z]{1,2}:[0-9]{1,4}|[0-9]{1,6})$', 'c')
);

-- Test durch Update
UPDATE acc_vehic
SET identicator = 'ZF:54:74'
WHERE vehicle_id = 1;

UPDATE acc_vehic
SET identicator = 'd:s:ß'
WHERE vehicle_id = 1;

UPDATE acc_vehic
SET identicator = '10:MP:92'
WHERE vehicle_id = 1;
```

### Aufgabe 6 - Wiederholung
Liste für alle Personen den Verbrauch an Kraftstoff auf (Missachte hier die unterschiedlichen Kraftstoffe). Dabei ist interessant, wie viel Liter die einzelne Person getankt hat und wie viel Euro sie für Kraftstoffe ausgegeben hat.

#### Lösung
```sql
Deine Lösung
```

### Aufgabe 7 - Wiederholung
Liste die Tankstellen absteigend sortiert nach der Kundenanzahl über alle Jahre.

#### Lösung
```sql
Deine Lösung
```

### Aufgabe 8 - Wiederholung
Erweitere das Datenbankmodell um ein Fahrtenbuch, sowie es Unternehmen für ihren Fuhrpark führen. Dabei ist relevant, welche Person an welchem Tag ab wie viel Uhr ein Fahrzeug für die Reise belegt, wie viele Kilometer zurück gelegt wurden und wann die Person das Fahrzeug wieder abgibt.

Berücksichtige bitte jegliche Constraints!

#### Lösung
```sql
Deine Lösung
```






