CREATE OR REPLACE VIEW vet_clinic.vet_snapshot_view AS
	SELECT CURRENT_DATE , * from vet_clinic.vet
	
-- Komentarz oraz opis działania w jednym	
COMMENT ON VIEW vet_clinic.vet_snapshot_view 
	IS 'Snapshot dostępnych wekerynarzy z bierzącego dnia dnia.';
	

select * from vet_clinic.vet_snapshot_view

-- ##############################################################################

-- v.visit_date = (NOW() - INTERVAL '10 DAY')::DATE

CREATE OR REPLACE VIEW vet_clinic.kwerenda_b6_query AS
select v.office_id, o.office_number, o.office_type 
from vet_clinic.visit v inner join vet_clinic.office o 
	on v.office_id=o.office_id
where v.visit_date = (NOW())::DATE
	and v.visit_time between 
		(select date_trunc('minute', TIMESTAMP '2013-12-17 12:27:00')::TIME - INTERVAL' 15 minute')
		and (select date_trunc('minute', TIMESTAMP '2013-12-17 12:27:00')::TIME + INTERVAL '15 minute')


-- Komentarz oraz opis działania w jednym
COMMENT ON VIEW vet_clinic.kwerenda_b6_query
IS 'Widok aktulanie zajętych sal w klinice.';

select * from vet_clinic.kwerenda_b6_query

-- ##############################################################################

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
order by taken_time_start, office_id

-- Komentarz oraz opis działania w jednym
COMMENT ON VIEW vet_clinic.kwerenda_b7_query
	IS 'Okresy w jakich sale są zajęte w przeciągu dnia segregowanie przez czas następnie salę.';
	
select * from vet_clinic.kwerenda_b7_query

-- ##############################################################################

CREATE OR REPLACE VIEW vet_clinic.kwerenda_a2_query AS
select owner_id, count(pet_id) as owned_pets
from vet_clinic.pet
group by owner_id
order by owned_pets DESC

-- Komentarz oraz opis działania w jednym
COMMENT ON VIEW vet_clinic.kwerenda_a2_query
	IS 'Ilosc petow jaka posiadaja ownerzy segregowana po ilosci.';
	
select * from vet_clinic.kwerenda_a2_query

-- ##############################################################################

CREATE OR REPLACE VIEW vet_clinic.kwerenda_a3_query AS
select vet_id, count(visit_id)
from vet_clinic.personnel
group by vet_id
order by vet_id DESC

-- Komentarz oraz opis działania w jednym
COMMENT ON VIEW vet_clinic.kwerenda_a3_query
	IS 'Ilosc wizit w jakich dany lekarz dral udzial.';
	
select * from vet_clinic.kwerenda_a3_query

-- ##############################################################################

CREATE OR REPLACE VIEW vet_clinic.kwerenda_a4_query AS
select address_id
from vet_clinic.address
where address_id not in (
	select address_id from vet_clinic.address)
order by address_id DESC

-- Komentarz oraz opis działania w jednym
COMMENT ON VIEW vet_clinic.kwerenda_a4_query
	IS 'Pokazuje adresy ktore nie sa przypaisane do żadnego owenera.';
	
select * from vet_clinic.kwerenda_a4_query

-- ##############################################################################

CREATE OR REPLACE VIEW vet_clinic.kwerenda_a5_query AS
select *
from vet_clinic.contact
where email_address is NULL

-- Komentarz oraz opis działania w jednym
COMMENT ON VIEW vet_clinic.kwerenda_a5_query
	IS 'Pokazuje rekordy w tabeli contact ktore nie zawieraja addresu email.';
	
select * from vet_clinic.kwerenda_a5_query

-- ##############################################################################

-- 1

CREATE OR REPLACE VIEW vet_clinic.kwerenda_B1_query AS	 

select count(personnel.visit_id ) as "Ilosc Wizyt" ,vet.first_name , vet.last_name from vet_clinic.personnel
inner join vet_clinic.vet  on personnel.vet_id = vet.vet_id
group by vet.vet_id
order by (select count(personnel.visit_id )) desc;

-- Komentarz oraz opis działania w jednym
COMMENT ON VIEW vet_clinic.kwerenda_B1_query
	IS 'Zliczenie ilości wizyt dla danego lekarza posortowane malejąco';

-- ##############################################################################
-- 2

CREATE OR REPLACE VIEW vet_clinic.kwerenda_B2_query AS	 

SELECT leki.drug_name, leki.suma FROM
 	(SELECT drug_name,
     RANK() OVER (ORDER BY COUNT(*) DESC) AS liczba_lekow,
 	 COUNT(*) AS suma
	 from vet_clinic.prescribed_drug
	inner join vet_clinic.drugs on drugs.id_drug = prescribed_drug.id_drug
	 GROUP BY 1) leki
WHERE leki.liczba_lekow = 1
ORDER BY 1;		

-- Komentarz oraz opis działania w jednym
COMMENT ON VIEW vet_clinic.kwerenda_B2_query
	IS 'Zliczenie wszystkich leków i wyświetlenie najczęściej wybieranego leku';

-- ##############################################################################
-- 3

CREATE OR REPLACE VIEW vet_clinic.kwerenda_B3_query AS	 

select pet.pet_name as "Stali klienci " from vet_clinic.visit
inner join vet_clinic.pet on pet.pet_id = visit.pet_id
where pet.pet_id in (select pet_id from vet_clinic.visit group by pet_id  having count(*) > 4);

-- Komentarz oraz opis działania w jednym
COMMENT ON VIEW vet_clinic.kwerenda_B3_query
	IS 'Wyświetlamy zwierzaki które są stałym klientami tzn. ilośc ich wizyy jest większa niż 4 ';

-- ##############################################################################
-- 4 

CREATE OR REPLACE VIEW vet_clinic.kwerenda_B4_query AS	 

SELECT o.name, o.last_name,  a.city , a.street ,a.house_number
FROM vet_clinic.owner o
   JOIN (SELECT address_id
         FROM vet_clinic.owner
         GROUP BY address_id HAVING count(*) > 1) AS cities
      USING (address_id)
inner join vet_clinic.address a on a.address_id = o.address_id;

-- Komentarz oraz opis działania w jednym
COMMENT ON VIEW vet_clinic.kwerenda_B4_query
	IS 'Wyświetlamy osoby które posiadają ten sam adres oraz wyświetlamy ten adres';

-- ##############################################################################
-- 5

CREATE OR REPLACE VIEW vet_clinic.kwerenda_B5_query AS	 
	  
select pet.pet_name, drugs.drug_name, visit.visit_date, visit.visit_time, vet.first_name, vet.last_name from vet_clinic.visit 
inner join vet_clinic.prescribed_drug on prescribed_drug.visit_id =  visit.visit_id
inner join vet_clinic.drugs on drugs.id_drug = prescribed_drug.id_drug
inner join vet_clinic.pet on pet.pet_id = visit.pet_id
inner join vet_clinic.personnel on personnel.visit_id = visit.visit_id
inner join vet_clinic.vet on vet.vet_id = personnel.vet_id;

-- Komentarz oraz opis działania w jednym
COMMENT ON VIEW vet_clinic.kwerenda_B5_query
	IS 'Karta Pacjenta . Dla każdego pacjenta wypisana data przyjęcia , podane leki oraz przyjmujący weterynarz';

-- ##############################################################################
-- 8


CREATE OR REPLACE VIEW vet_clinic.kwerenda_B8_query AS

SELECT zabiegi.description, zabiegi.suma_zabiegow FROM
 	(SELECT description,
     RANK() OVER (ORDER BY COUNT(*) DESC) AS liczba_zabiegow ,
 	 COUNT(*) AS suma_zabiegow
	 from vet_clinic.visit
	
	 GROUP BY 1) zabiegi 
order by suma_zabiegow desc;

-- Komentarz oraz opis działania w jednym
COMMENT ON VIEW vet_clinic.kwerenda_B8_query
	IS 'Zwracamy wszystkie wykonane zabiegi zliczone i wyświetlone od najczęściej wykonanych ';


-- ##############################################################################
-- 9

CREATE OR REPLACE VIEW vet_clinic.kwerenda_B9_query AS	  

SELECT  leki.suma , leki.first_name , leki.last_name from
 	(SELECT 
	 first_name,last_name,
     RANK() OVER (ORDER BY COUNT(*) DESC) AS liczba_lekow,
 	 COUNT(*) AS suma
	 from vet_clinic.prescribed_drug
	 inner join vet_clinic.visit on visit.visit_id = prescribed_drug.visit_id
	inner join vet_clinic.drugs on drugs.id_drug = prescribed_drug.id_drug	
	 
	inner join vet_clinic.personnel on personnel.visit_id = visit.visit_id
	 

	 
	 inner join vet_clinic.vet on vet.vet_id = personnel.vet_id
	 GROUP BY vet.first_name, vet.last_name) leki

ORDER BY 1 desc ;

-- Komentarz oraz opis działania w jednym
COMMENT ON VIEW vet_clinic.kwerenda_B9_query
	IS 'Wyświetlenie lekarzy i zliczenie ile wypisali oni leków';

-- ##############################################################################
-- 10 

CREATE OR REPLACE VIEW vet_clinic.kwerenda_B10_query AS	

SELECT  leki.name as "Nazwa Specjalizacji",  leki.specjalizacje as "Liczb specjalizacji" from 
 	(SELECT 
	 name,
     RANK() OVER (ORDER BY COUNT(*) DESC) AS liczba_spec,
 	 COUNT(*) AS specjalizacje
	 from vet_clinic.vet_speciality
	 inner join vet_clinic.speciality on speciality.id_speciality = vet_speciality.id_speciality 
	 GROUP BY 1) leki

ORDER BY leki.specjalizacje desc ;

-- Komentarz oraz opis działania w jednym
COMMENT ON VIEW vet_clinic.kwerenda_b10_query
	IS 'Wyświetlamy specjalizacje naszych lekarzy zliczając je  w kolejności od największej  '; 





