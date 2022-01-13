
-- Ten oto wyzwalacz sprawdza podczas dodawnia nowych właścicieli (ownerów) pupilów (petów)
-- czy aby takie właścicela z takim samym imieniem i nazwiskiem już nie ma.

CREATE TRIGGER on_owner_insert_trigger
  BEFORE INSERT
  ON vet_clinic.owner
  FOR EACH ROW
  EXECUTE PROCEDURE vet_clinic.check_owner_insert();


CREATE OR REPLACE FUNCTION vet_clinic.check_owner_insert()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL
  AS
$$
BEGIN
	IF (SELECT ROW(name, last_name) FROM vet_clinic.owner
		BEGIN
	   	WHERE owner.name = NEW.name and owner.last_name = NEW.last_name) is not null then
		RAISE EXCEPTION 'Owner with this name and last name already exists!';
	   	RETURN NULL
	END IF;

	RETURN NEW;
END;
$$

-- #########################################################################

-- Te oto 3 wyzwalacze i 2 praktycznie takie same funkcję aktualizują widok
-- b7_query z harmonogrammem dzsiejszego dnia w razie jakich kolwiek zmian
-- w bazie w tabeli visit.

CREATE FUNCTION vet_clinic.update_b7_query_view_new() 
	RETURNS trigger
    LANGUAGE plpgsql
    AS 
$$
BEGIN
  CREATE OR REPLACE VIEW vet_clinic.kwerenda_b7_query AS
	SELECT office_id,
		visit_time as taken_time_start,
		CASE
			WHEN visit_type = 'wizyta'
				THEN visit_time + INTERVAL '15 minute'
			WHEN visit_type = 'kontrola'
				THEN visit_time + INTERVAL '15 minute'
			WHEN visit_type = 'zabieg'
				THEN visit_time + INTERVAL '45 minute'
			WHEN visit_type = 'badanie'
				THEN visit_time + INTERVAL '30 minute'
		END taken_time_stop
	FROM vet_clinic.visit
	where visit_date = (NOW())::DATE
	order by taken_time_start, office_id;
  RETURN NEW;
END;
$$;

CREATE FUNCTION vet_clinic.update_b7_query_view_old() 
	RETURNS trigger
    LANGUAGE plpgsql
    AS 
$$
BEGIN
  CREATE OR REPLACE VIEW vet_clinic.kwerenda_b7_query AS
	SELECT office_id,
		visit_time as taken_time_start,
		CASE
			WHEN visit_type = 'wizyta'
				THEN visit_time + INTERVAL '15 minute'
			WHEN visit_type = 'kontrola'
				THEN visit_time + INTERVAL '15 minute'
			WHEN visit_type = 'zabieg'
				THEN visit_time + INTERVAL '45 minute'
			WHEN visit_type = 'badanie'
				THEN visit_time + INTERVAL '30 minute'
		END taken_time_stop
	FROM vet_clinic.visit
	where visit_date = (NOW())::DATE
	order by taken_time_start, office_id;
  RETURN OLD;
END;
$$;

CREATE TRIGGER update_view_on_visits_insert
    AFTER INSERT
	ON vet_clinic.visit
    EXECUTE PROCEDURE vet_clinic.update_b7_query_view_new();
	
CREATE TRIGGER update_view_on_visits_update
    AFTER UPDATE
	ON vet_clinic.visit
    EXECUTE PROCEDURE vet_clinic.update_b7_query_view_new();
	
CREATE TRIGGER update_view_on_visits_delete
    AFTER DELETE
	ON vet_clinic.visit
    EXECUTE PROCEDURE vet_clinic.update_b7_query_view_old();

  -- TESTY! -------------- poniżej
	
select * from vet_clinic.kwerenda_b7_query
insert into vet_clinic.visit (description, visit_type, visit_date, visit_time, pet_id, office_id)
	values ('Pacjent zachorował na psią odmanę koronawirusa, podano ibuprom', 'wizyta', '2022-01-12', '14:00:00', 4, 3)
	
UPDATE vet_clinic.visit SET office_id=6 WHERE visit_date = '2022-01-12'

DELETE FROM vet_clinic.visit
  WHERE visit_date = '2022-01-12'
	
select * from vet_clinic.visit where visit_date = '2022-01-12'

-- #########################################################################

-- Wyzwalacz nie pozwala na dodanie lekarza z tą samą sprcializacją do
-- jednej wizyty

CREATE OR REPLACE FUNCTION vet_clinic.check_personnel_overpopullation_func() 
	RETURNS trigger
    LANGUAGE plpgsql
    AS
$$
DECLARE
	temprow record;
	vet_to_check record;
BEGIN
	RAISE NOTICE 'entering loop';
	FOR temprow IN (select vs.vet_id, s.name as spec_name
						from vet_clinic.vet_speciality vs
						inner join vet_clinic.speciality s on vs.id_speciality=s.id_speciality
						where vet_id = NEW.vet_id)
	LOOP
		RAISE NOTICE 'entering second loop';
		FOR vet_to_check in (select vet_id as vet_id from vet_clinic.personnel 
								where visit_id=NEW.visit_id)
		LOOP
			RAISE NOTICE 'entering if in second loop';
			IF temprow.spec_name IN (select s.name as spec_name
						from vet_clinic.vet_speciality vs
						inner join vet_clinic.speciality s on vs.id_speciality=s.id_speciality
						where vet_id = vet_to_check.vet_id) THEN
				RETURN NULL;
			END IF;		
		END LOOP;
   	END LOOP;
	
  RETURN NEW;
END;
$$;

CREATE TRIGGER check_personnel_overpopullation
    BEFORE INSERT
	ON vet_clinic.personnel
	FOR EACH ROW
    EXECUTE PROCEDURE vet_clinic.check_personnel_overpopullation_func();
	

insert into vet_clinic.personnel (visit_id, vet_id)
	values (3,6),(3,7)
	
select * from vet_clinic.personnel where visit_id = 3

