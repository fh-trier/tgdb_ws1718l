# Tutorium - Grundlagen Datenbanken - Blatt 7

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

Analyse den untenstehenden anonymen PL/SQL-Codeblock. Was macht er?
Passe den Codeblock so an, dass nicht nur die ID des Benutzers ausgegeben wird, sondern auch der Vor- und Nachname, als auch die Anzahl seiner Fahrzeuge.

```sql
DECLARE
  v_account_id account.account_id%TYPE;

BEGIN
  SELECT MAX(a.account_id) INTO v_account_id
  FROM account a
  WHERE a.surname LIKE 'P%';

  DBMS_OUTPUT.PUT_LINE('Der neuste Benutzer mit dem Anfangsbuchstaben P im Nachnamen hat die ID ' || v_account_id);

EXCEPTION
  WHEN NO_DATA_FOUND
    THEN RAISE_APPLICATION_ERROR(-20001, 'Es wurde kein Benutzer gefunden');
  WHEN OTHERS
    THEN DBMS_OUTPUT.PUT_LINE ('Folgender unerwarteter Fehler ist aufgetreten: ');
  RAISE;
END;
/
```

#### Lösung
Dieser anonyme PL/SQL-Codeblock gibt den Benutzer mit der größten ID aus, deren Nachname mit einem `P` beginnt.

```sql
DECLARE
  v_account_id account.account_id%TYPE;
  v_forename account.forename%TYPE;
  v_surname account.surname%TYPE;
  v_anzahl NUMBER(38);
BEGIN
  SELECT a.account_id ,
         a.forename,
         a.surname,
         (SELECT COUNT(*)
         FROM acc_vehic
         WHERE account_id = a.account_id) INTO v_account_id, v_forename, v_surname, v_anzahl
  FROM account a
  WHERE a.account_id = (
    SELECT MAX(account_id)
    FROM account
    WHERE surname LIKE 'P%'
  );

DBMS_OUTPUT.PUT_LINE('Der neuste Benutzer ist ' || v_forename || ' ' || v_surname || ' mit der ID ' || v_account_id || ' und hat ' || v_anzahl || ' Fahrzeuge.');

EXCEPTION
  WHEN NO_DATA_FOUND
    THEN RAISE_APPLICATION_ERROR(-20001, 'Es wurde kein Benutzer gefunden');
  WHEN OTHERS
    THEN DBMS_OUTPUT.PUT_LINE ('Folgender unerwarteter Fehler ist aufgetreten: ');
  RAISE;
END;
/
```

### Aufgabe 2
Schreibe einen anonymen PL/SQL-Codeblock, der die Tankstelle mit der kleinsten ID auflistet mit Informationen über den Anbieter und der Addresse. Implementiere ein `IF-ELSE` Konstrukt, dass wenn eine Tankstelle mehr Kundenbesuch erziehlt hat, als alle anderen im Durchschnitt, die Tankstelle als gut Besucht gekennzeichnet wird in der Ausgabe. Andernfalls wird die Tankstelle als schlecht Besucht gekennzeichnet.

#### Lösung
```sql
DECLARE
  v_account_id account.account_id%TYPE;
  v_provider_name provider.provider_name%TYPE;
  v_street gas_station.street%TYPE;
  v_plz address.plz%TYPE;
  v_city address.city%TYPE;
  v_country country.country_name%TYPE;
  v_avg NUMBER;
  v_avg_all NUMBER;
BEGIN
  SELECT p.provider_name,
         gs.street,
         a.plz,
         a.city,
         c.country_name,
         (
          SELECT AVG(receipt_id)
          FROM receipt
          WHERE gas_station_id = gs.gas_station_id
        ) INTO v_provider_name, v_street, v_plz, v_city, v_country, v_avg
  FROM gas_station gs
    INNER JOIN address a ON (a.address_id = gs.address_id)
    INNER JOIN provider p ON (gs.provider_id = p.provider_id)
    INNER JOIN country c ON (gs.country_id = c.country_id)
  WHERE gs.gas_station_id = (
    SELECT MIN(gas_station_id)
    FROM gas_station
  );

  SELECT AVG(receipt_id) INTO v_avg_all
  FROM receipt;

  IF v_avg >= v_avg_all
  THEN
    DBMS_OUTPUT.PUT_LINE('Die Tankstelle ' || v_provider_name || ', ' || v_street || ', ' || v_plz || ', ' || v_city || ', ' || v_country || ' wird gut besucht, da der Durchschnitt von ' || v_avg || ' über dem gesamten Durchschnit von ' || v_avg_all || '  ist.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Die Tankstelle ' || v_provider_name || ', ' || v_street || ', ' || v_plz || ', ' || v_city || ', ' || v_country || ' wird schlecht besucht, da der Durchschnitt von ' || v_avg || ' unter dem gesamten Durchschnit von ' || v_avg_all || ' ist.');
  END IF;


EXCEPTION
  WHEN NO_DATA_FOUND
    THEN RAISE_APPLICATION_ERROR(-20001, 'Es wurde kein Benutzer gefunden');
  WHEN OTHERS
    THEN DBMS_OUTPUT.PUT_LINE ('Folgender unerwarteter Fehler ist aufgetreten: ');
    RAISE;
END;
/
```

### Aufgabe 3
Analysiere den untenstehenden anonymen PL/SQL-Code. Was macht er?
Passe den Codeblock so an, dass für jede Tankstelle alle Kunden die dort einmal tanken, waren ausgegeben werden.

```sql
DECLARE
BEGIN
  DBMS_OUTPUT.PUT_LINE('Liste alle Tankstellen aus Deutschland');
  DBMS_OUTPUT.PUT_LINE('____________________________________________');
  FOR rec_gs IN (  SELECT p.provider_name, gs.street, a.plz, a.city, c.country_name
                    FROM gas_station gs
                      INNER JOIN address a ON (a.address_id = gs.address_id)
                      INNER JOIN provider p ON (gs.provider_id = p.provider_id)
                      INNER JOIN country c ON (gs.country_id = c.country_id)
                    WHERE c.country_name LIKE 'Deutschland') LOOP
    DBMS_OUTPUT.PUT_LINE('++ ' || rec_gs.provider_name || ' ++ ' || rec_gs.street || ' ++ ' || rec_gs.plz || ' ++ ' || rec_gs.city || ' ++ ' || rec_gs.country_name);
  END LOOP;
END;
/
```

#### Lösung
```sql
DECLARE
BEGIN
  DBMS_OUTPUT.PUT_LINE('Liste alle Tankstellen aus Deutschland');
  DBMS_OUTPUT.PUT_LINE('____________________________________________');
  FOR rec_gs IN ( SELECT p.provider_name, gs.street, a.plz, a.city, c.country_name, gs.gas_station_id
                  FROM gas_station gs
                    INNER JOIN address a ON (a.address_id = gs.address_id)
                    INNER JOIN provider p ON (gs.provider_id = p.provider_id)
                    INNER JOIN country c ON (gs.country_id = c.country_id)
                  WHERE c.country_name LIKE 'Deutschland') LOOP
    DBMS_OUTPUT.PUT_LINE('++ ' || rec_gs.provider_name || ' ++ ' || rec_gs.street || ' ++ ' || rec_gs.plz || ' ++ ' || rec_gs.city || ' ++ ' || rec_gs.country_name);
    FOR rec_a IN ( SELECT a.surname, a.forename
                    FROM account a
                      INNER JOIN receipt r ON (r.account_id = a.account_id)
                    WHERE r.gas_station_id = rec_gs.gas_station_id) LOOP
      DBMS_OUTPUT.PUT_LINE('++++ ' || rec_a.forename || ', ' || rec_a.surname);
    END LOOP;
  END LOOP;
END;
/
```

### Aufgabe 4
Schreibe einen anonymen PL/SQL-Codeblock, der alle deine Fahrzeuge auflistet und die dazugehörigen Belege inkl. Betrag, der ausgegeben wurde für jeden Tankvorgang.

#### Lösung
```sql
DECLARE
BEGIN
  DBMS_OUTPUT.PUT_LINE('Liste alle Fahrzeuge mit Belegen');
  DBMS_OUTPUT.PUT_LINE('____________________________________________');
  FOR rec_r IN (SELECT p.producer_name, v.version, accv.alias, accv.acc_vehic_id
                FROM acc_vehic accv
                  INNER JOIN vehicle v ON (accv.vehicle_id = v.vehicle_id)
                  INNER JOIN producer p ON (v.producer_id = p.producer_id)
                WHERE accv.account_id = 1) LOOP
    DBMS_OUTPUT.PUT_LINE('++ ' || rec_r.producer_name || ', ' || rec_r.version || ', ' || rec_r.alias || ' ++');
    FOR rec_b IN (SELECT r.price_l, r.liter, r.price_l+r.liter AS summe, g.gas_name
                  FROM receipt r
                    INNER JOIN gas g ON (r.gas_id = g.gas_id)
                  WHERE r.acc_vehic_id = rec_r.acc_vehic_id) LOOP
      DBMS_OUTPUT.PUT_LINE('++++ ' || rec_b.price_l || ', ' || rec_b.liter || ', ' || rec_b.summe || ', ' || rec_b.gas_name || ' ++++');
    END LOOP;
  END LOOP;
END;
/
```
