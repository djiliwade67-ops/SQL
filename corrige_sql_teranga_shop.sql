
-- PARTIE 0 - ECHAUFFEMENT : LES MOTS DU METIER

-- 0.1 Familles de commandes
--   LDD / DDL (definition)      : CREATE, ALTER, DROP, TRUNCATE
--       (TRUNCATE est classe en LDD : il agit sur la table entiere)
--   LMD / DML (manipulation)    : INSERT, UPDATE, DELETE
--   LID / DQL (interrogation)   : SELECT
--   LCD / DCL (controle droits) : GRANT, REVOKE
--   TCL (transactions)          : COMMIT, ROLLBACK

-- 0.2 Cle primaire, cle etrangere, UNIQUE
--   - Cle primaire : identifie chaque ligne de facon unique. Jamais NULL,
--     une seule par table.
--   - Cle etrangere : colonne(s) qui reference la cle primaire d'une autre
--     table. Garantit l'integrite referentielle (on ne peut pas pointer
--     vers une ligne inexistante).
--   - UNIQUE : interdit les doublons, mais accepte NULL ; une table peut
--     avoir plusieurs contraintes UNIQUE.
--   Cle primaire de ligne_commande = (id_commande, id_produit).
--   Pourquoi composee : une commande contient plusieurs produits et un
--   produit figure dans plusieurs commandes (association plusieurs-a-
--   plusieurs). Aucune colonne seule n'identifie une ligne ; le couple, si :
--   un produit n'apparait qu'une fois par commande, avec sa quantite.

-- 0.3 NULL
--   NULL = valeur absente ou inconnue (ce n'est ni 0, ni la chaine vide).
--   Toute comparaison avec NULL (=, <>, <...) donne UNKNOWN, pas TRUE.
--   WHERE ne garde que les lignes dont la condition est TRUE : donc
--   "WHERE email = NULL" ne renvoie jamais rien.
--   Il faut ecrire : WHERE email IS NULL.

-- 0.4 Ordre d'evaluation logique
--   1. FROM (et jointures)   2. WHERE   3. GROUP BY   4. HAVING
--   5. SELECT (expressions et alias)   6. ORDER BY   7. LIMIT
--   Le WHERE est evalue AVANT le SELECT : l'alias n'existe pas encore.
--   On ne peut donc pas l'utiliser dans le WHERE (il faut repeter
--   l'expression). ORDER BY, evalue apres, accepte l'alias.
--   MySQL tolere l'alias dans HAVING, pas PostgreSQL.

-- 0.5 DELETE / TRUNCATE / DROP
--   DELETE FROM produit;  supprime les lignes (WHERE possible, annulable
--                         par ROLLBACK, structure conservee, compteur
--                         auto-increment non remis a zero).
--   TRUNCATE TABLE produit; vide toute la table d'un coup (rapide, pas de
--                         WHERE, en general non annulable, structure
--                         conservee, compteur reinitialise).
--   DROP TABLE produit;   supprime la table elle-meme : donnees, structure,
--                         contraintes, index.

-- 0.6 Lecture du script (d'apres le schema decrit ; citez la ligne exacte
--     de votre script pour justifier)
--   (a) OUI : le lien est porte par commande (FOREIGN KEY id_client).
--       Rien dans client n'oblige a avoir une commande ; l'enonce indique
--       d'ailleurs 2 clients sans commande.
--   (b) OUI : id_vendeur est facultatif dans commande (NULL = commande en
--       ligne) ; la cle etrangere est nullable.
--   (c) NON : id_client est NOT NULL avec FOREIGN KEY vers client.


-- PARTIE A - DEFINIR LA STRUCTURE (LDD)

-- A1 Table livraison
CREATE TABLE livraison (
  id_livraison   INT PRIMARY KEY,
  id_commande    INT NOT NULL,
  date_livraison DATE NOT NULL,
  frais          INT NOT NULL DEFAULT 1000,
  zone           VARCHAR(10) NOT NULL,
  FOREIGN KEY (id_commande) REFERENCES commande(id_commande)
);

-- A2 Ajouter, verifier, supprimer une colonne
-- (a)
ALTER TABLE client ADD COLUMN quartier VARCHAR(40);
-- (b) MySQL : DESCRIBE ; PostgreSQL : \d client
DESCRIBE client;
-- (c)
ALTER TABLE client DROP COLUMN quartier;

-- A3 E-mail unique
ALTER TABLE client ADD CONSTRAINT uq_client_email UNIQUE (email);
-- Question subsidiaire : les 4 NULL ne posent PAS de probleme. NULL etant
-- "inconnu", deux NULL ne sont pas consideres comme egaux : MySQL et
-- PostgreSQL acceptent plusieurs NULL dans une colonne UNIQUE
-- (SQL Server n'en accepte qu'un).

-- A4 Predictions (instructions commentees : a tester une par une)
-- (a) INSERT INTO produit VALUES (601, 'Cahier 200 pages', 0, 100, 6);
--     ACCEPTEE, sauf CHECK (prix_unitaire > 0) dans le script. La categorie
--     6 existe (elle est vide) : la cle etrangere est respectee.
-- (b) INSERT INTO commande VALUES (1021, '2026-07-01', 99, NULL, 'WAVE', 'EN COURS');
--     REFUSEE : cle etrangere id_client, le client 99 n'existe pas.
-- (c) INSERT INTO client VALUES (13, 'Sy', 'Coumba', 'Kedougou', '771234501', NULL, '2026-07-01');
--     ACCEPTEE : id libre, e-mail NULL autorise.
-- (d) INSERT INTO commande VALUES (1021, '2026-07-01', 3, NULL, 'PAYPAL', 'EN COURS');
--     REFUSEE si le script contient le CHECK sur mode_paiement
--     (WAVE, ORANGE MONEY, ESPECES, CARTE), ce que l'enonce laisse supposer.
-- (e) INSERT INTO ligne_commande VALUES (1001, 101, 1, 16500);
--     REFUSEE si la ligne (1001, 101) existe deja (cle primaire dupliquee)
--     ou si le produit 101 n'existe pas (cle etrangere).
-- (f) DELETE FROM client WHERE id_client = 1;
--     REFUSEE : le client 1 (Awa Diop) a des commandes, la cle etrangere
--     de commande l'interdit.
-- (g) DELETE FROM client WHERE id_client = 12;
--     ACCEPTEE : Babacar Kane n'a jamais commande, aucune ligne enfant.


-- PARTIE B - MANIPULER LES DONNEES (LMD)
-- (relancer teranga_shop.sql a la fin de cette partie)

-- B1 Nouvelle cliente
INSERT INTO client (id_client, nom, prenom, ville, telephone, email, date_inscription)
VALUES (13, 'Sy', 'Coumba', 'Kedougou', '771234513', NULL, CURRENT_DATE);

-- B2 Hausse de 5 % sur l'electronique
-- ROUND pour garder des prix entiers en FCFA.
UPDATE produit
SET prix_unitaire = ROUND(prix_unitaire * 1.05)
WHERE id_categorie = 2;

SELECT * FROM produit WHERE id_categorie = 2;

-- B3 Commandes en cours passees avant le 15 juin 2026
UPDATE commande
SET statut = 'LIVREE'
WHERE statut = 'EN COURS'
  AND date_commande < '2026-06-15';
-- Le nombre de lignes modifiees est affiche par le client SQL
-- ("rows affected"). Pour le prevoir, faire avant un SELECT COUNT(*) avec
-- le meme WHERE.

-- B4 Suppression de clients
-- (a)
DELETE FROM client WHERE id_client = 12;
-- (b) REFUSE (violation de cle etrangere), donc commente :
-- DELETE FROM client WHERE id_client = 1;
--     Awa Diop est referencee par des lignes de commande : supprimer le
--     parent laisserait des commandes orphelines. Pour la supprimer, il
--     faut d'abord supprimer (ou reaffecter) ses commandes et leurs lignes,
--     ou avoir declare ON DELETE CASCADE sur la cle etrangere.

-- B5 Suppression de la commande 1014
DELETE FROM ligne_commande WHERE id_commande = 1014;
DELETE FROM commande       WHERE id_commande = 1014;
-- Ordre impose : ligne_commande (enfant) reference commande (parent).
-- On supprime les enfants d'abord, puis le parent ; dans l'autre sens, la
-- cle etrangere bloquerait.

-- >>> RELANCEZ teranga_shop.sql ICI pour retrouver les donnees d'origine <<<


-- PARTIE C - INTERROGER UNE SEULE TABLE

-- C1
SELECT designation, prix_unitaire
FROM produit
ORDER BY prix_unitaire DESC;

-- C2
SELECT nom, prenom, ville
FROM client
WHERE ville IN ('Dakar', 'Thies')   -- adapter l'orthographe a vos donnees (Thiès)
ORDER BY nom;

-- C3
SELECT *
FROM produit
WHERE prix_unitaire BETWEEN 5000 AND 20000;

-- C4
SELECT *
FROM client
WHERE nom LIKE 'D%';

-- C5 (doit renvoyer 4 clients)
SELECT *
FROM client
WHERE email IS NULL;

-- C6
SELECT DISTINCT ville
FROM client
ORDER BY ville;

-- C7
SELECT designation, prix_unitaire
FROM produit
ORDER BY prix_unitaire DESC
LIMIT 3;

-- C8
SELECT *
FROM commande
WHERE id_vendeur IS NULL
  AND date_commande BETWEEN '2026-01-01' AND '2026-06-30';

-- C9
-- L'expression est repetee dans le WHERE (alias inutilisable, cf. 0.4) ;
-- l'alias est en revanche utilisable dans l'ORDER BY.
SELECT designation, prix_unitaire * stock AS valeur_stock
FROM produit
WHERE prix_unitaire * stock > 200000
ORDER BY valeur_stock DESC;


-- PARTIE D - JOINTURES INTERNES

-- D1 Syntaxe moderne
SELECT p.designation, c.libelle
FROM produit p
JOIN categorie c ON c.id_categorie = p.id_categorie;

-- D1 Ancienne syntaxe
SELECT p.designation, c.libelle
FROM produit p, categorie c
WHERE c.id_categorie = p.id_categorie;
-- 17 lignes : "Livres et Papeterie" n'apparait pas (aucun produit).

-- D2
SELECT co.id_commande, co.date_commande, co.statut
FROM commande co
JOIN client cl ON cl.id_client = co.id_client
WHERE cl.nom = 'Diop' AND cl.prenom = 'Awa';

-- D3
SELECT DISTINCT cl.nom, cl.prenom, co.date_commande
FROM client cl
JOIN commande co       ON co.id_client = cl.id_client
JOIN ligne_commande lc ON lc.id_commande = co.id_commande
JOIN produit p         ON p.id_produit = lc.id_produit
WHERE p.designation = 'Smartphone 128 Go';

-- D4
SELECT p.designation, lc.quantite, lc.prix_vente,
       lc.quantite * lc.prix_vente AS montant
FROM ligne_commande lc
JOIN produit p ON p.id_produit = lc.id_produit
WHERE lc.id_commande = 1006;

-- D5 Auto-jointure
SELECT v.nom, v.prenom, c.nom AS nom_chef, c.prenom AS prenom_chef
FROM vendeur v
JOIN vendeur c ON c.id_vendeur = v.id_chef;
-- 4 lignes sur 5 vendeurs. Le DIRECTEUR manque : son id_chef vaut NULL,
-- aucune ligne de c ne correspond, et une jointure interne elimine les
-- lignes sans correspondance (voir F3 pour corriger).

-- D6
-- DISTINCT evite qu'un client ayant paye plusieurs fois par Wave apparaisse
-- plusieurs fois. Si deux clients peuvent avoir les memes nom et prenom,
-- ajouter cl.id_client au SELECT.
SELECT DISTINCT cl.nom, cl.prenom
FROM client cl
JOIN commande co ON co.id_client = cl.id_client
WHERE cl.ville = 'Dakar'
  AND co.mode_paiement = 'WAVE';


-- PARTIE E - AGREGATS ET REGROUPEMENTS

-- E1
SELECT COUNT(*)                  AS nb_produits,
       MIN(prix_unitaire)        AS prix_min,
       MAX(prix_unitaire)        AS prix_max,
       ROUND(AVG(prix_unitaire)) AS prix_moyen
FROM produit;

-- E2
SELECT statut, COUNT(*) AS nb_commandes
FROM commande
GROUP BY statut;

-- E3
SELECT ville, COUNT(*) AS nb_clients
FROM client
GROUP BY ville
ORDER BY nb_clients DESC;

-- E4
SELECT co.id_commande,
       SUM(lc.quantite * lc.prix_vente) AS montant_total
FROM commande co
JOIN ligne_commande lc ON lc.id_commande = co.id_commande
WHERE co.statut = 'LIVREE'
GROUP BY co.id_commande
ORDER BY montant_total DESC;

-- E5
SELECT cat.libelle,
       SUM(lc.quantite * lc.prix_vente) AS chiffre_affaires
FROM commande co
JOIN ligne_commande lc ON lc.id_commande = co.id_commande
JOIN produit p         ON p.id_produit = lc.id_produit
JOIN categorie cat     ON cat.id_categorie = p.id_categorie
WHERE co.statut = 'LIVREE'
GROUP BY cat.id_categorie, cat.libelle
ORDER BY chiffre_affaires DESC;

-- E6
SELECT ville, COUNT(*) AS nb_clients
FROM client
GROUP BY ville
HAVING COUNT(*) >= 2;

-- E7 (tous statuts confondus)
SELECT cl.nom, cl.prenom, COUNT(*) AS nb_commandes
FROM client cl
JOIN commande co ON co.id_client = cl.id_client
GROUP BY cl.id_client, cl.nom, cl.prenom
HAVING COUNT(*) >= 3;

-- E8
SELECT v.nom, v.prenom,
       SUM(lc.quantite * lc.prix_vente) AS chiffre_affaires
FROM vendeur v
JOIN commande co       ON co.id_vendeur = v.id_vendeur
JOIN ligne_commande lc ON lc.id_commande = co.id_commande
WHERE co.statut = 'LIVREE'
GROUP BY v.id_vendeur, v.nom, v.prenom
HAVING SUM(lc.quantite * lc.prix_vente) > 150000;

-- E9 WHERE ou HAVING ?
-- Le WHERE filtre les LIGNES avant le regroupement (statut, annee).
-- Le HAVING filtre les GROUPES apres le calcul de l'agregat (total > 100000).
SELECT co.mode_paiement,
       SUM(lc.quantite * lc.prix_vente) AS chiffre_affaires
FROM commande co
JOIN ligne_commande lc ON lc.id_commande = co.id_commande
WHERE co.statut = 'LIVREE'
  AND co.date_commande BETWEEN '2026-01-01' AND '2026-12-31'
GROUP BY co.mode_paiement
HAVING SUM(lc.quantite * lc.prix_vente) > 100000;


-- PARTIE F - PONT VERS LA L2

-- F1 Tous les clients, y compris sans commande
-- COUNT(co.id_commande) ne compte pas les NULL : les 2 clients sans
-- commande affichent 0. (Piege de G7 avec COUNT(*).)
SELECT cl.nom, cl.prenom, COUNT(co.id_commande) AS nb_commandes
FROM client cl
LEFT JOIN commande co ON co.id_client = cl.id_client
GROUP BY cl.id_client, cl.nom, cl.prenom;

-- F2 Categories sans produit (attendu : "Livres et Papeterie")
SELECT c.libelle
FROM categorie c
LEFT JOIN produit p ON p.id_categorie = c.id_categorie
WHERE p.id_produit IS NULL;

-- F3 D5 avec tous les vendeurs ; "Direction" pour celui sans chef
-- 5 lignes. Pour le directeur, c.nom est NULL et COALESCE le remplace.
SELECT v.nom, v.prenom,
       COALESCE(c.nom, 'Direction') AS chef
FROM vendeur v
LEFT JOIN vendeur c ON c.id_vendeur = v.id_chef;

-- F4 Produits plus chers que la moyenne
SELECT designation, prix_unitaire
FROM produit
WHERE prix_unitaire > (SELECT AVG(prix_unitaire) FROM produit);

-- F5 Produit(s) le(s) moins cher(s) (ex aequo inclus, contrairement a
-- ORDER BY ... LIMIT 1)
SELECT designation, prix_unitaire
FROM produit
WHERE prix_unitaire = (SELECT MIN(prix_unitaire) FROM produit);

-- F6 Clients sans commande, avec NOT IN
-- Fonctionne ici car commande.id_client est NOT NULL. Si la sous-requete
-- pouvait renvoyer un NULL, NOT IN ne renverrait plus rien (voir J2).
SELECT nom, prenom
FROM client
WHERE id_client NOT IN (SELECT id_client FROM commande);

-- F7 UNION : contacts clients + vendeurs
-- ORDER BY unique, a la fin, sur l'ensemble. UNION ALL serait equivalent
-- ici (la 3e colonne distingue deja les lignes) et plus rapide.
SELECT nom, prenom, 'client' AS type_contact FROM client
UNION
SELECT nom, prenom, 'vendeur' AS type_contact FROM vendeur
ORDER BY nom;

-- F8 CASE : gammes de produits
-- Les WHEN sont evalues dans l'ordre : le 2e n'est teste que si le 1er est
-- faux, donc "<= 30000" suffit pour la tranche 5000 a 30000 incluse.
SELECT designation, prix_unitaire,
       CASE
         WHEN prix_unitaire < 5000   THEN 'Economique'
         WHEN prix_unitaire <= 30000 THEN 'Standard'
         ELSE 'Premium'
       END AS gamme
FROM produit
ORDER BY prix_unitaire;

-- FIN (parties 0 a F)
