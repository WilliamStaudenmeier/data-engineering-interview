-- Question 1: Retrieve all active patients
-- Write a query to return all patients who are active.
-- (I'm assuming I should just return all columns)

SELECT * FROM public."Patient" WHERE active = true;

-- Question 2: Find encounters for a specific patient
-- Given a patient_id, retrieve all encounters for that patient, including the status and encounter date.
-- (I'm assuming that I should create a variable for patient_id, so that we can pass as a parameter)

DEALLOCATE ALL;
PREPARE my_query (UUID) AS 
SELECT * FROM public."Encounter" WHERE patient_id = $1;
EXECUTE my_query('395714a3-216f-4526-b648-d8b24ef324e1'); -- you can replace this variable with any ID

-- Question 3: List all observations recorded for a patient
-- Write a query to fetch all observations for a given patient_id, showing the observation type, value, unit, and recorded date.
-- (I'm assuming that I should create a variable for patient_id, so that we can pass as a parameter)

DEALLOCATE ALL;
PREPARE my_query (UUID) AS 
SELECT 
	id AS observation_id
	, patient_id
	, type AS observation_type
	, value
	, unit
	, recorded_at

FROM public."Observation" WHERE patient_id = $1;
EXECUTE my_query('395714a3-216f-4526-b648-d8b24ef324e1'); -- you can replace this variable with any ID

-- Question 4: Find the most recent encounter for each patient
-- Retrieve each patient’s most recent encounter (based on encounter_date). Return the patient_id, encounter_date, and status.


WITH cte as (

	SELECT 
	patient_id
	,encounter_date
	, status
	, RANK() OVER (PARTITION BY patient_id ORDER BY encounter_date DESC) ranks
	FROM public."Encounter"

)

SELECT 
	patient_id
	, encounter_date
	, status	
FROM cte
where ranks = 1
order by patient_id desc

-- Question 5: Find patients who have had encounters with more than one practitioner
-- Write a query to return a list of patient IDs who have had encounters with more than one distinct practitioner.

WITH cte AS (
SELECT
	patient_id
	, COUNT(DISTINCT practitioner_id) counts
FROM public."Encounter"
GROUP BY patient_id
)

SELECT patient_id FROM cte WHERE counts>1;

-- Question 6: Find the top 3 most prescribed medication
-- Write a query to find the three most commonly prescribed medications from the MedicationRequest table, sorted by the number of prescriptions.

SELECT
	medication_name
	, COUNT(DISTINCT id) AS num_prescriptions
FROM public."MedicationRequest"
GROUP BY medication_name
ORDER BY 2 DESC
LIMIT 3

-- Question 7: Get practitioners who have never prescribed any medication
-- Write a query to find all practitioners who do not appear in the MedicationRequest table as a prescribing practitioner.


-- The columns weren't specified, so I'm assuming return all columns
SELECT * FROM public."Practitioner"
WHERE id NOT IN (SELECT DISTINCT practitioner_id AS id FROM public."MedicationRequest");

SELECT * FROM public."Practitioner"
WHERE name NOT IN (SELECT DISTINCT name FROM public."MedicationRequest");

-- Question 8: Find the average number of encounters per patient
-- Calculate the average number of encounters per patient, rounded to two decimal places.


-- There are two patients Amy Allen and Terrence Lloyd who are not in Encounter table, this can change the answer


-- If we include patients with 0 encounters:
WITH patients_w_encounters AS (
	SELECT
		patient_id
		, COUNT(DISTINCT id) counts
	FROM public."Encounter"
	GROUP BY 1	
),

patients_w_no_encounters AS (
	SELECT
		id AS patient_id
		, 0 counts
	FROM public."Patient" 
	WHERE id NOT IN (SELECT patient_id AS id FROM public."Encounter")
),

combined AS (
	SELECT * FROM patients_w_no_encounters
	UNION ALL
	SELECT * FROM patients_w_encounters
)

SELECT ROUND(AVG(counts),2) FROM combined;

-- If we don't include patients with 0 encounters:
WITH cte as (
	SELECT
		patient_id
		, COUNT(DISTINCT id) counts
	FROM public."Encounter"
	GROUP BY 1	
)

SELECT ROUND(AVG(counts),2) FROM cte;


-- Question 9: Identify patients who have never had an encounter but have a medication request
-- Write a query to find patients who have a record in the MedicationRequest table but no associated encounters in the Encounter table.

SELECT * FROM public."Patient" 
WHERE id NOT IN (SELECT patient_id AS id FROM public."Encounter") AND id IN (SELECT patient_id AS id FROM public."MedicationRequest");

-- Question 10: Determine patient retention by cohort
-- Write a query to count how many patients had their first encounter in each month (YYYY-MM format) 
-- and still had at least one encounter in the following six months.

WITH firsts AS (
    SELECT 
        patient_id, 
        MIN(encounter_date) AS first_encounter_date
    FROM "Encounter"
    GROUP BY patient_id
),
seconds AS (
    SELECT DISTINCT fe.patient_id
    FROM firsts fe
    JOIN "Encounter" e 
        ON fe.patient_id = e.patient_id
        AND e.encounter_date > fe.first_encounter_date
        AND e.encounter_date <= fe.first_encounter_date + INTERVAL '6 months'
)
SELECT 
    DATE_TRUNC('month', fe.first_encounter_date) AS encounter_month,
    COUNT(DISTINCT fe.patient_id) AS patient_count
FROM firsts fe
JOIN seconds se ON fe.patient_id = se.patient_id
GROUP BY encounter_month
ORDER BY encounter_month;



