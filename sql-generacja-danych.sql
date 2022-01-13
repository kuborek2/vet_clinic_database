

/**
	Źródła:
	Specializacje weterynaryjne: http://wetstegny.pl/nasza-oferta/specjalizacje-lekarzy/
	Lista Medykamentów: https://edraurban.pl/ssl/book-sample-file/saunders-handbook-leki-w-weterynarii-male-i-duze-zwierzeta/pdf/leki_w_weterynarii.pdf
	Iminiona petów: https://www.petplace.com/article/dogs/pet-care/top-1200-pet-names/
*/

-- ##############################################################################
-- Domeny używane w bazie danych

-- Domena używana do kodu pocztowego
CREATE DOMAIN vet_clinic.zipcode varchar(10)  
    CONSTRAINT valid_zipcode 
    CHECK (VALUE ~ '[A-Z0-9-]+');	

-- Domena używana do walidacji addresu email
CREATE DOMAIN vet_clinic.email_address varchar(325)
	CONSTRAINT valid_email_address
  	CHECK ( value ~ '@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$' );

-- Domena używana do walidacji numeru telefonu
CREATE DOMAIN vet_clinic.phone_number varchar(12)
    CONSTRAINT valid_phone_number
    CHECK (VALUE ~ '(?<!\w)((?(+|00)?48)?)?[ -]?\d{3}[ -]?\d{3}[ -]?\d{3}(?!\w)' );	

-- Domena używana do walidacji typu wizyty
CREATE DOMAIN vet_clinic.domain_visit_type AS TEXT
CHECK(
   VALUE = 'wizyta'
OR VALUE = 'kontrola'
OR VALUE = 'zabieg'
OR VALUE = 'badanie'
);

-- ##############################################################################
-- Sekwencje używane w bazie danych
			
CREATE SEQUENCE vet_clinic.owner_id_seq
INCREMENT 1
START 1
MINVALUE 1
MAXVALUE 9223372036854775807
CACHE 10;

CREATE SEQUENCE vet_clinic.address_id_seq
INCREMENT 1
START 1
MINVALUE 1
MAXVALUE 9223372036854775807
CACHE 10;

CREATE SEQUENCE vet_clinic.contact_id_seq
INCREMENT 1
START 1
MINVALUE 1
MAXVALUE 9223372036854775807
CACHE 10;

CREATE SEQUENCE vet_clinic.drugs_id_seq
INCREMENT 1
START 1
MINVALUE 1
MAXVALUE 9223372036854775807
CACHE 10;

CREATE SEQUENCE vet_clinic.vet_speciality_id_seq
INCREMENT 1
START 1
MINVALUE 1
MAXVALUE 9223372036854775807
CACHE 10;

CREATE SEQUENCE vet_clinic.pet_id_seq
INCREMENT 1
START 1
MINVALUE 1
MAXVALUE 9223372036854775807
CACHE 10;

CREATE SEQUENCE vet_clinic.visit_id_seq
INCREMENT 1
START 1
MINVALUE 1
MAXVALUE 9223372036854775807
CACHE 10;

-- ##############################################################################
-- Przykład dodawania domeny do tabeli, był na potrzebny w formie przypomienia

CREATE TABLE sekwencje.uczestnicy (
    -- Tu musisz dać niżej te sekwencje dla ownerów !!!!!!!!!!!!!!!!!!!!!
    -- id INTEGER DEFAULT nextval('vet_clinic.address_id_seq'::regclass) PRIMARY KEY,
	id INTEGER DEFAULT nextval('vet_clinic.owner_id_seq'::regclass) PRIMARY KEY,
	imie VARCHAR(30) NOT NULL,
	nazwisko VARCHAR(50) NOT NULL,
	data_urodzenia DATE NOT NULL,
	kraj VARCHAR(40) NOT NULL DEFAULT 'Polska'
);

-- ##############################################################################
-- Funckja która pozwala na generowanie danych

select * from vet_clinic.generuj_dane()
CREATE OR REPLACE FUNCTION vet_clinic.generuj_dane()
RETURNS BOOLEAN AS $GENERATOR$

DECLARE 
	pocztowy_kod CHARACTER(6);
	miejscowosc_id INTEGER;
    miejscowosc_nazw CHARACTER VARYING(100);
	imie CHARACTER VARYING(20);
	nazwisko CHARACTER VARYING(50);
	address_id INTEGER;
	contact_id INTEGER;
	liczba_specializacji INTEGER;
	id_speciality_func INTEGER;
	petowe_imie CHARACTER VARYING(30);
	ownerowe_id INTEGER;
	
	-- Słowniki lokalne
	ulica VARCHAR[];
	visit_type_array VARCHAR[];
	
	-- Liczba danych do uzupełnienia
	liczba_adresow CONSTANT INTEGER DEFAULT 5000;
	liczba_kontaktow CONSTANT INTEGER DEFAULT 5000;
	liczba_owenerow CONSTANT INTEGER DEFAULT 5000;
	liczba_petow CONSTANT INTEGER DEFAULT 5000;	
	liczba_visitow CONSTANT INTEGER DEFAULT 5000;
	
BEGIN

	-- Usunięcie istniejących danych z tabel
	DELETE FROM vet_clinic.visit
	DELETE FROM vet_clinic.pet
	DELETE FROM vet_clinic.owner;
    DELETE FROM vet_clinic.address;
	DELETE FROM vet_clinic.contact;
	DELETE FROM vet_clinic.vet_speciality;
	DELETE FROM vet_clinic.vet
	DELETE FROM vet_clinic.speciality

	-- Ustawienie wartości sekwencji
	ALTER SEQUENCE vet_clinic.owner_id_seq RESTART WITH 1;
    ALTER SEQUENCE vet_clinic.address_id_seq RESTART WITH 1;
	ALTER SEQUENCE vet_clinic.contact_id_seq RESTART WITH 1;
	ALTER SEQUENCE vet_clinic.vet_speciality_id_seq RESTART WITH 1;
	ALTER SEQUENCE vet_clinic.pet_id_seq RESTART WITH 1;
	ALTER SEQUENCE vet_clinic.vet_clinic.visit_id_seq RESTART WITH 1;

	-- Rekrdy do Tabeli z specializacjami (vet_clinic.speciality)	
	insert into vet_clinic.speciality (id_speciality,name) values 
	(1,'Chirurgia weterynaryjna' ),
	(2,'Choroby przeżuwaczy' ),
	(3,'Choroby koni' ),
	(4,'Choroby trzody chlewnej' ),
	(5,'Choroby psów i kotów' ),
	(6,'Choroby drobiu oraz ptaków ozdobnych' ),
	(7,'Choroby zwierząt futerkowych' ),
	(8,'Użytkowanie i patologia zwierząt laboratoryjnych' ),
	(9,'Choroby ryb'),
	(10,'Choroby zwierząt nieudomowionych (egzotycznych)' ),
	(11,'Rozród zwierząt' ),
	(12,'Radiologia weterynaryjna' ),
	(13,'Weterynaryjna diagnostyka laboratoryjna' ),
	(14,'Epizootiologia i administracja weterynaryjna' );

	-- Rekrdy do Tabeli z weterynarzami (vet_clinic.vet)	
	insert into vet_clinic.vet (vet_id, first_name, last_name, contact_id, address_id ) values
	(1,'Mikołaj','Norka',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER),(SELECT trunc(1 + random()*SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER)),
	(2,'Adam','Ryba', (SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER),(SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER) ),
	(3,'Bożena','Bykowska',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) , (SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER)),

	(4,'Maria','Tur',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) ,(SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER) ),
	(5,'Anastazja','Ćwierk',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) ,(SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER) ),
	(6,'Miłosz','Jeż',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) , (SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER)),

	(7,'Bartłomiej','Byk',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) ,(SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER) ),
	(8,'Stanisław','Słoniowska',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) ,(SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER) ),
	(9,'Magdalena','Motyl',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) , (SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER)),

	(10,'Czesława','Wilk',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) ,(SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER) ),
	(11,'Barbara','Tygrys',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) ,(SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER) ),
	(12,'Alojzy','Mrówka', (SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER),(SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER) );



	-- Słowniki lokalne
	ulica := ARRAY['Owocowa', 'Leśna', 'Dąbrowskiego', 'Tarnowska', 'Żabieńska', 'Krajowa', 'Brzozowa', 'Mała', 'Duża', 'Kwadratowa', 'Ziołowa'];
	visit_type_array := ARRAY['wizyta', 'kontrola', 'zabieg', 'badanie'];

    -- Uzupełnienie danymi tabeli adress
    RAISE NOTICE 'Generuję dane dla tabeli address';

    FOR i IN 1..liczba_adresow
	LOOP
		SELECT miejscowosc.id_miejscowosci INTO STRICT miejscowosc_id
		FROM slownik.miejscowosc
		WHERE miejscowosc.id_miejscowosci = (SELECT trunc(1 + random()*(SELECT max(miejscowosc.id_miejscowosci) FROM slownik.miejscowosc))::INTEGER);
        -- @TESTING RAISE NOTICE 'Wybrano miejscowość (miejscowosc_id = %)', miejscowosc_id;

        SELECT miejscowosc_sbq.kod_pocztowy, miejscowosc_sbq.miejscowosc INTO STRICT pocztowy_kod, miejscowosc_nazw
		FROM
			(SELECT DISTINCT ON (miejscowosc) miejscowosc, kod_pocztowy FROM slownik.miejscowosc
			WHERE miejscowosc = (SELECT miejscowosc.miejscowosc FROM slownik.miejscowosc WHERE miejscowosc.id_miejscowosci = miejscowosc_id)) AS miejscowosc_sbq;

        INSERT INTO vet_clinic.address(city, postal_code, street, house_number, apartment_number)
		VALUES (
            miejscowosc_nazw,
            pocztowy_kod,
			ulica[(SELECT trunc(1 + random() * cardinality(ulica))::INTEGER)],
			
			(SELECT rpad(trunc(random() * 100)::INTEGER::VARCHAR, 2, '0')),
			(SELECT rpad(trunc(random() * 10)::INTEGER::VARCHAR, 1, '0')));

    END LOOP;
	RAISE NOTICE 'Dodano % krajów', (SELECT COUNT(*) FROM vet_clinic.address);

    RAISE NOTICE 'Generuję dane dla tabeli contact';
    FOR i IN 1..liczba_kontaktow
	LOOP

		SELECT imie.imie INTO STRICT imie
		FROM slownik.imie
		WHERE imie.id_imienia = (SELECT trunc(1 + random()*(SELECT max(imie.id_imienia) FROM slownik.imie))::INTEGER);

		SELECT nazwisko.nazwisko INTO STRICT nazwisko
		FROM slownik.nazwisko
		WHERE nazwisko.id_nazwiska = (SELECT trunc(1 + random()*(SELECT max(nazwisko.id_nazwiska) FROM slownik.nazwisko))::INTEGER);

        BEGIN
				
			INSERT INTO vet_clinic.contact(phone_number, email_address)
			VALUES (
				(SELECT rpad(trunc(random() * 1000000000)::BIGINT::VARCHAR, 9, '0')),
				lower(nazwisko) || '_' || lower(imie) || trunc(random() * 100)::VARCHAR || '@' ||
				(CASE trunc(random() * 5)::INTEGER
					WHEN 0 THEN 'gmail.com'
					WHEN 1 THEN 'onet.pl'
					WHEN 2 THEN 'wp.pl'
					WHEN 3 THEN 'interia.pl'
					WHEN 4 THEN 'hotmail.com'
				END));

		EXCEPTION WHEN unique_violation THEN
			-- Nic nie rób. Spróbuj dodać kolejny rekord w pętli.
		END;

	END LOOP;
	RAISE NOTICE 'Dodano % uczestników', (SELECT COUNT(*) FROM vet_clinic.contact);

	-- Uzupełnienie danymi tabeli owner
	RAISE NOTICE 'Generuję dane dla tabeli owener';
	FOR i IN 1..liczba_owenerow
	LOOP

		SELECT imie.imie INTO STRICT imie
		FROM slownik.imie
		WHERE imie.id_imienia = (SELECT trunc(1 + random()*(SELECT max(imie.id_imienia) FROM slownik.imie))::INTEGER);

		SELECT nazwisko.nazwisko INTO STRICT nazwisko
		FROM slownik.nazwisko
		WHERE nazwisko.id_nazwiska = (SELECT trunc(1 + random()*(SELECT max(nazwisko.id_nazwiska) FROM slownik.nazwisko))::INTEGER);

		SELECT address.address_id INTO STRICT address_id
		FROM vet_clinic.address
		WHERE address.address_id = (SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER);

		SELECT contact.contact_id INTO STRICT contact_id
		FROM vet_clinic.contact
		WHERE contact.contact_id = (SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER);

		BEGIN
			BEGIN

				INSERT INTO vet_clinic.owner(name, last_name, address_id, contact_id)
				VALUES(
					imie,
					nazwisko,
					address_id,
					contact_id
				);

				EXCEPTION WHEN unique_violation THEN
				-- Nic nie rób. Spróbuj dodać kolejny rekord w pętli.
			END;

			EXCEPTION WHEN not_null_violation THEN
			-- Nic nie rób. Spróbuj dodać kolejny rekord w pętli.

		END;
	
	END LOOP;
	RAISE NOTICE 'Dodano % ownerow', (SELECT COUNT(*) FROM vet_clinic.owner);

	-- Uzupełnienie danymi tabeli vet_speciality
	RAISE NOTICE 'Generuję dane dla tabeli vet_speciality';
	FOR i IN 1..((SELECT max(vet.vet_id) FROM vet_clinic.vet)::INTEGER)
	LOOP

		SELECT trunc(1 + random()*3) INTO STRICT liczba_specializacji;

		FOR j IN 1..liczba_specializacji
		LOOP

			SELECT speciality.id_speciality INTO STRICT id_speciality_func
			FROM vet_clinic.speciality
			WHERE speciality.id_speciality = (SELECT trunc(1 + random()*(SELECT max(speciality.id_speciality) FROM vet_clinic.speciality))::INTEGER);

			BEGIN

				IF EXISTS (SELECT * FROM vet_clinic.vet_speciality WHERE vet_speciality.vet_id = i AND vet_speciality.id_speciality=id_speciality_func) THEN
				-- do nothing if ceration vet already has this specilaity
				ELSE
					INSERT INTO vet_clinic.vet_speciality(vet_id, id_speciality)
						VALUES(
							i,
							id_speciality_func
						);
				END IF;

			END;

		END LOOP;
		
	END LOOP;
	RAISE NOTICE 'Dodano % vet_speiclity', (SELECT COUNT(*) FROM vet_clinic.vet_speciality);

	-- Uzupełnienie danymi tabeli pet
	RAISE NOTICE 'Generuję dane dla tabeli pet';
	FOR i IN 1..liczba_petow
	LOOP

		SELECT imie_zwierze.imie_zwierzecia INTO STRICT petowe_imie
			FROM slownik.imie_zwierze
			WHERE imie_zwierze.id_zwierzecia = (SELECT trunc(1 + random()*(SELECT max(imie_zwierze.id_zwierzecia) FROM slownik.imie_zwierze))::INTEGER);

		SELECT owner.owner_id INTO STRICT ownerowe_id
		FROM vet_clinic.owner
		WHERE owner.owner_id = (SELECT trunc(1 + random()*(SELECT max(owner.owner_id) FROM vet_clinic.owner))::INTEGER);

		BEGIN

			IF EXISTS (SELECT * FROM vet_clinic.pet WHERE pet.owner_id = ownerowe_id AND pet.pet_name=petowe_imie) THEN
			-- do nothing if ceration vet already has this specilaity
			ELSE
				INSERT INTO vet_clinic.pet(pet_name, weight, owner_id)
					VALUES(
						petowe_imie,
						(SELECT trunc(1 + random()*100)::INTEGER),
						ownerowe_id
					);
			END IF;

		END;

	END LOOP;
	RAISE NOTICE 'Dodano % krajów', (SELECT COUNT(*) FROM vet_clinic.pet);

	-- Uzupełnienie danymi tabeli visit
	RAISE NOTICE 'Generuję dane dla tabeli visit';
	FOR i IN 1..liczba_visitow
	LOOP

		INSERT INTO vet_clinic.visit(description, visit_type, visit_date, visit_time, pet_id, office_id)
			VALUES(
				(SELECT opis.opis FROM slownik.opis
					WHERE opis.opis = (SELECT trunc(1 + random()*(SELECT max(opis.id_opisu) FROM slownik.opis))::INTEGER)),
				visit_type_array[(SELECT trunc(1 + random() * cardinality(ulica))::INTEGER)],
				(SELECT (now() - trunc(random()*101) * '1 day'::INTERVAL)::DATE),
				(SELECT date_trunc('minute',(now() - trunc(random()*101) * '1 day'::INTERVAL)::Time)),
				(SELECT trunc(1 + random()*(SELECT max(pet.pet_id) FROM vet_clinic.pet)),
				(SELECT trunc(1 + random()*(SELECT max(office.office_id) FROM vet_clinic.office)),
			);

	END LOOP;
	RAISE NOTICE 'Dodano % krajów', (SELECT COUNT(*) FROM vet_clinic.visit);

	RETURN TRUE; 

END;

$GENERATOR$ 
LANGUAGE 'plpgsql';

-- ############################################################################################
-- Funkcja służąca do generowania danych do tabelek prescribed_drugs oraz personnel

select * from generuj_dane_drugs_personnel()

CREATE OR REPLACE FUNCTION vet_clinic.generuj_dane_drugs_personnel()

RETURNS BOOLEAN AS $GENERATOR$
DECLARE

	liczba_lekow CONSTANT INTEGER DEFAULT 5000;
	liczba_wizyt CONSTANT INTEGER DEFAULT 5000;

BEGIN
	RAISE NOTICE 'Generuję dane dla tabeli Personnel';

	FOR i IN 1..liczba_wizyt
		LOOP
		INSERT INTO vet_clinic.personnel (visit_id,vet_id) values (i,(SELECT trunc(1 + random()*(SELECT max(vet.vet_id) FROM vet_clinic.vet))::INTEGER));
	END LOOP;

	RAISE NOTICE 'Generuję dane dla tabeli Prescribed Drugs';

	FOR i IN 1..liczba_lekow
		LOOP
		INSERT INTO vet_clinic.prescribed_drug (visit_id,id_drug) values (i,(SELECT trunc(1 + random()*(SELECT max(id_drug) FROM vet_clinic.drugs))::INTEGER));
	END LOOP;

	RETURN TRUE; 
	END;

$GENERATOR$ 
LANGUAGE 'plpgsql';

-- ############################################################################################
-- Dane które dodawaliśmy ręcznie do bazy czyli, dane dotyczące dostepnych leków, lekarzy
-- ich specializacji oraz dostepnych sal w klinice weterynaryjnej

-- Rekrdy do Tabeli z lekami (vet_clinic.drugs)
INSERT INTO vet_clinic.drugs (drug_name, description)
Value
	('Izoproterenolu chlorowodorek', 'Agoniści receptora beta-adrenergicznego'),
	('Bromokryptyny metanosulfonian', 'Agoniści receptorów dopaminowych'),
	('Pergolid', 'Agoniści receptorów dopaminowych'),
	('Selegiliny chlorowodorek', 'Agoniści receptorów dopaminowych'),
	('Betanecholu chlorek', 'Agoniści receptora beta-adrenergicznego'),
	('Dinoprost trometaminy', 'Analogi prostaglandyn'),
	('Prostaglandyna F-2 alfa', 'Analogi prostaglandyn'),
	('Atipamezolu chlorowodorek', 'Antagoniści receptora adrenergicznego alfa-2'),
	('Yohimbina', 'Antagoniści receptora adrenergicznego alfa-2'),
	('Atenolol', 'Antagoniści receptora beta-adrenergicznego '),
	('Esmololu chlorowodorek', 'Antagoniści receptora beta-adrenergicznego '),
	('Metoprololu winian', 'Antagoniści receptora beta-adrenergicznego '),
	('Sotalolu chlorowodorek', 'Antagoniści receptora beta-adrenergicznego '),
	('Hiosciamina', 'Antagoniści receptorów muskarynowych
(parasympatykolityki)'),
	('Atropiny siarczan', 'Antagoniści receptorów muskarynowych
(parasympatykolityki)'),
	('Neopankreatyna', 'Antagoniści receptorów opioidowych'),
	('Danazol', 'Hormony'),
	('Desmopresyny octan', 'Hormony'),
	('Estradiolu cyklopentanopropionian', 'Hormony'),
	('Gonadotropina kosmówkowa', 'Hormony'),
	('Kortykotropina', 'Hormony'),
	('Liotyroniny sól sodowa', 'Hormony'),
	('Megestrolu octan', 'Hormony'),
	('Testosteron', 'Hormony'),
	('Finasteryd', 'Hormony, antagoniści'),
	('Tyreoliberyna', 'Hormony, działające na tarczycę'),
	('Oksytocyna', 'Hormony, indukujące poród'),
	('Metylotestosteron', 'Hormony, środki anaboliczne'),
	('Oksymetolon', 'Hormony, środki anaboliczne'),
	('Neostygmina', 'Inhibitory acetylocholinoesterazy'),
	('Pirydostygminy bromek', 'Inhibitory acetylocholinoesterazy'),
	('Fludrokortyzonu octan', 'Kortykosteroid, hormon'),
	('Gliceryna', 'Lek moczopędny, przeczyszczający'),
	('Dwuwęglan sodu', 'Leki alkalizujące'),
	('Digoksyna', 'Leki działające inotropowo dodatnio'),
	('Pimobendan', 'Leki działające inotropowo dodatnio'),
	('Karbimazol', 'Leki hamujące czynność tarczycy'),
	('Metimazol (tiamazol)', 'Leki hamujące czynność tarczycy'),
	('Trilostan', 'Leki hamujące wydzielanie hormonów kory
nadnerczy'),
	('Chlorotiazyd', 'Leki moczopędne'),
	('Furosemid', 'Leki moczopędne'),
	('Mannitol', 'Leki moczopędne'),
	('Spironolakton', 'Leki moczopędne'),
	('Trazodon', 'Leki modyfikujące zachowanie'),
	('Fluoksetyny chlorowodorek', 'Leki modyfikujące zachowanie, SSRI
(inhibitory zwrotnego wychwytu serotoniny)'),
	('Imipraminy chlorowodorek', 'Leki modyfikujące zachowanie,
trójpierścieniowe leki przeciwdepresyjne'),
	('Doksepina', 'Leki modyfikujące zachowanie,
trójpierścieniowe leki przeciwdepresyjne'),
	('Auranofina', 'Leki o działaniu immunosupresyjnym'),
	('Azatiopryna', 'Leki o działaniu immunosupresyjnym'),
	('Cyklosporyna', 'Leki o działaniu immunosupresyjnym'),
	('Takrolimus', 'Leki o działaniu immunosupresyjnym'),
	('Węglan litu', 'Leki o działaniu stymulującym układ
immunologiczny'),
	('Gemfibrozyl', 'Leki obniżające stężenie lipoprotein, fibraty'),
	('Leki osłaniające funkcję wątroby', 'S-adenozylometionina (SAM)'),
	('Epinefryna', 'Leki pobudzające układ adrenergiczny'),
	('Fenylopropanoloaminy chlorowodorek', 'Leki pobudzające układ adrenergiczny'),
	('Pseudoefedryny chlorowodorek', 'Leki pobudzające układ adrenergiczny'),
	('Doksapramu chlorowodorek', 'Leki pobudzające układ oddechowy
(analeptyki)'),
	('Racemetionina', 'Leki pobudzające wydzielanie soku
żołądkowego'),
	('Metoksamina', 'Leki powodujące skurcz naczyń (wazopresyjne)'),
	('Wazopresyna', 'Leki powodujące skurcz naczyń (wazopresyjne)'),
	('Cyzapryd', 'Leki prokinetyczne'),
	('Lidokainy chlorowodorek', 'Leki prokinetyczne'),
	('Tegaserod', 'Leki prokinetyczne'),
	('Edrofonium chlorek', 'Leki przeciw nużliwości mięśni'),
	('Amiodaron', 'Leki przeciwarytmiczne'),
	('Chinidyny glukonian', 'Leki przeciwarytmiczne'),
	('Chinidyny poligalakturonian', 'Leki przeciwarytmiczne'),
	('Dizopiramid', 'Leki przeciwarytmiczne'),
	('Lidokaina', 'Leki przeciwarytmiczne'),
	('Prokainamidu chlorowodorek', 'Leki przeciwarytmiczne'),
	('Werapamilu chlorowodorek', 'Leki przeciwarytmiczne, blokery kanału
wapniowego'),
	('Chloramfenikol', 'Leki przeciwbakteryjne'),
	('Florfenikol', 'Leki przeciwbakteryjne');

-- Rekrdy do Tabeli z specializacjami (vet_clinic.speciality)	
insert into vet_clinic.speciality (id_speciality,name) values 
(1,'Chirurgia weterynaryjna' ),
(2,'Choroby przeżuwaczy' ),
(3,'Choroby koni' ),
(4,'Choroby trzody chlewnej' ),
(5,'Choroby psów i kotów' ),
(6,'Choroby drobiu oraz ptaków ozdobnych' ),
(7,'Choroby zwierząt futerkowych' ),
(8,'Użytkowanie i patologia zwierząt laboratoryjnych' ),
(9,'Choroby ryb'),
(10,'Choroby zwierząt nieudomowionych (egzotycznych)' ),
(11,'Rozród zwierząt' ),
(12,'Radiologia weterynaryjna' ),
(13,'Weterynaryjna diagnostyka laboratoryjna' ),
(14,'Epizootiologia i administracja weterynaryjna' );

-- Rekrdy do Tabeli z salami (vet_clinic.office)	
insert into vet_clinic.office (office_id,office_number,office_type) values 
(1,1,'Sala Przyjęć'),
(2,2,'Sala Przyjęć'),
(3,3,'Sala Przyjęć'),
(4,4,'Sala Zabiegowa'),
(5,5,'Sala Zabiegowa'),
(6,6,'Usg, Tomograf, Rentgen');

-- Rekrdy do Tabeli z weterynarzami (vet_clinic.vet)	
insert into vet_clinic.vet (vet_id, first_name, last_name, contact_id, address_id ) values
(1,'Mikołaj','Norka',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER),(SELECT trunc(1 + random()*SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER)),
(2,'Adam','Ryba', (SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER),(SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER) ),
(3,'Bożena','Bykowska',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) , (SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER)),

(4,'Maria','Tur',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) ,(SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER) ),
(5,'Anastazja','Ćwierk',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) ,(SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER) ),
(6,'Miłosz','Jeż',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) , (SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER)),

(7,'Bartłomiej','Byk',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) ,(SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER) ),
(8,'Stanisław','Słoniowska',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) ,(SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER) ),
(9,'Magdalena','Motyl',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) , (SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER)),

(10,'Czesława','Wilk',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) ,(SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER) ),
(11,'Barbara','Tygrys',(SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER) ,(SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER) ),
(12,'Alojzy','Mrówka', (SELECT trunc(1 + random()*(SELECT max(contact.contact_id) FROM vet_clinic.contact))::INTEGER),(SELECT trunc(1 + random()*(SELECT max(address.address_id) FROM vet_clinic.address))::INTEGER) ),




	




