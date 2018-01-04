CREATE TABLE Artikel(
  artikelnr     NUMBER(10) NOT NULL,
  artikelgruppe NUMBER(10) NOT NULL,
  artikelname   VARCHAR2(40) NOT NULL,
  einzelpreis   NUMBER(10,2) NOT NULL,
  ADD CONSTRAINT PK_ARTIKEL PRIMARY KEY artikel
);

INSERT INTO artikel VALUES (1, 2, 'Lyoner 500g', 3.49);
INSERT INTO artikel VALUES (2, 2, 'Lyoner 1000g', 5.79);
INSERT INTO artikel VALUES (3, 2, 'Steak 200g', 14.99);
INSERT INTO artikel VALUES (4, 1, 'Mischbrot 350g', 2.29);
INSERT INTO artikel VALUES (5, 1, 'Schwarzbrot 400g', 4.19);
INSERT INTO artikel VALUES (7, 1, 'Weizenbrot 700g', 6.19);
COMMIT;

GRANT SELECT ON Artikel TO public;
