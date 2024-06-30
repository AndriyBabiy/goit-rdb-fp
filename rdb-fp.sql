-- Final Project
-- Q1
CREATE SCHEMA pandemic;

USE pandemic;

/*
-- Key Moment - Data Import --

While importing the data there were rows missing due to the value format being incorrect. 
To resolve this I adjusted all of the data-types to be text in order to correctly import all fo the data.

Row count = 10521
*/

SELECT
	*
FROM
	infectious_cases;
	
-- ALTER TABLE pandemic.infectious_cases MODIFY COLUMN `Year` YEAR NULL;

-- Q2 
/*
-- Data Normalization --

In order to normalize the data I decided to split it into two table as follows:
- entities - 
- infection_instances - 
*/

BEGIN; -- entites -- table creation
-- Code for droping table if needed
DROP TABLE IF EXISTS entities;

-- Creating the table
CREATE TABLE entities (
	id INT PRIMARY KEY AUTO_INCREMENT,
	Code VARCHAR(255),
    Entity VARCHAR(255)
);

-- Inserting data from infectious_cases
INSERT INTO entities (Code, Entity)
	SELECT 
		DISTINCT Code, Entity
	FROM
		infectious_cases ic
;

-- Testing
SELECT
	*
FROM
	entities;
END;

BEGIN; -- infection_instances -- table creation
-- Code for droping table if needed
DROP TABLE IF EXISTS infection_instances;

-- Creating the table
CREATE TABLE infection_instances (
	id INT PRIMARY KEY AUTO_INCREMENT,
    entity_id INT,
    `Year` YEAR,
	Number_yaws FLOAT,
    polio_cases FLOAT,
	cases_guinea_worm FLOAT,
    Number_rabies FLOAT,
    Number_malaria FLOAT,
    Number_hiv FLOAT,
	Number_tuberculosis FLOAT,
	Number_smallpox FLOAT,
	Number_cholera_cases FLOAT,
    FOREIGN KEY (entity_id) REFERENCES entities(id)
);

-- Inserting data from infectious_cases
INSERT INTO infection_instances (
    entity_id,
    `Year`,
	Number_yaws,
    polio_cases,
	cases_guinea_worm,
    Number_rabies,
    Number_malaria,
    Number_hiv,
	Number_tuberculosis,
	Number_smallpox,
	Number_cholera_cases
)
	SELECT 
		e.id as entity_id,
        CASE 
			WHEN LENGTH(ic.Year) = 4 AND ic.Year REGEXP '^[0-9]+$' THEN CAST(ic.Year AS YEAR)
			ELSE NULL
		END AS Year,
		-- CAST(ic.`Year` AS INT) AS YEAR, 
		CAST(NULLIF(ic.Number_yaws, '') AS FLOAT),
		CAST(NULLIF(ic.polio_cases, '') AS FLOAT),
		CAST(NULLIF(ic.cases_guinea_worm, '') AS FLOAT),
		CAST(NULLIF(ic.Number_rabies, '') AS FLOAT),
		CAST(NULLIF(ic.Number_malaria, '') AS FLOAT),
		CAST(NULLIF(ic.Number_hiv, '') AS FLOAT),
		CAST(NULLIF(ic.Number_tuberculosis, '') AS FLOAT),
		CAST(NULLIF(ic.Number_smallpox, '') AS FLOAT),
		CAST(NULLIF(ic.Number_cholera_cases, '') AS FLOAT)
	FROM
		infectious_cases ic
	JOIN
		entities e 
        ON e.Entity = ic.Entity
			AND e.Code = ic.Code
;

-- Testing
SELECT
	*
FROM
	infection_instances;
END;


-- Q3
SELECT
	entity_id,
    entity,
    code,
    ROUND(AVG(Number_rabies), 2) avg_rabies,
    ROUND(MAX(Number_rabies), 2) max_rabies,
    ROUND(MIN(Number_rabies), 2) min_rabies
FROM
	infection_instances ii
    LEFT JOIN entities e
		ON e.id = ii.entity_id
WHERE
	Number_rabies IS NOT NULL
GROUP BY
	entity_id
ORDER BY
	avg_rabies DESC
LIMIT 
	10
;

-- Q4

DROP FUNCTION IF EXISTS year_function;

DELIMITER //

CREATE FUNCTION year_function(
	year1 YEAR, 
    operation VARCHAR(255), 
    year2 YEAR 
)
RETURNS DATE
READS SQL DATA
BEGIN
	DECLARE result DATE;
    
    IF operation = 'full_date_start' THEN
		SET result = STR_TO_DATE(CONCAT(year1, '-01-01'), '%Y-%m-%d');
	ELSEIF operation = 'current_date' THEN
		SET result = CURRENT_DATE;
	ELSEIF operation = 'year_diff' THEN
		IF year2 > year1 THEN
			SET result = ABS(year2 - year1);
		ELSEIF year1 > year2 THEN
			SET result = ABS(year1 - year2);
		END IF;
	ELSE
		SET result = NULL;
	END IF;
    
    RETURN result;
END //

DELIMITER ;

DROP FUNCTION IF EXISTS year_computations;

DELIMITER //

CREATE FUNCTION year_computations(
	year1 YEAR, 
    operation VARCHAR(255), 
    year2 YEAR 
)
RETURNS INT
READS SQL DATA
BEGIN
	DECLARE result INT;
    
	IF operation = 'diff' THEN
		IF year2 > year1 THEN
			SET result = ABS(year2 - year1);
		ELSEIF year1 > year2 THEN
			SET result = ABS(year1 - year2);
		END IF;
	ELSE
		SET result = NULL;
	END IF;
    
    RETURN result;
END //

DELIMITER ;
	
SELECT
	entity_id,
    `Year`,
    year_function(Year, 'current_date', Year) as current_date_calc,
    year_function(Year, 'full_date_start', Year) as start_of_year,
    year_computations(Year, 'diff', YEAR(year_function(Year, 'current_date', Year))) as year_difference_between_dates,  
	Number_yaws,
    polio_cases,
	cases_guinea_worm,
    Number_rabies,
    Number_malaria,
    Number_hiv,
	Number_tuberculosis,
	Number_smallpox,
	Number_cholera_cases
FROM
	infection_instances ii;

-- Q5
DROP FUNCTION IF EXISTS years_to_today;

DELIMITER //

CREATE FUNCTION years_to_today(
	year1 YEAR
)
RETURNS INT
READS SQL DATA
BEGIN
	DECLARE result INT;
    
	SET result = ABS(YEAR(CURRENT_DATE) - YEAR(year_function(year1, 'full_date_start', year1)));
    
    RETURN result;
END //

DELIMITER ;

SELECT
	entity_id,
    `Year`,
    year_function(Year, 'full_date_start', Year) as start_of_year,
    years_to_today(Year) AS years_to_today,
	Number_yaws,
    polio_cases,
	cases_guinea_worm,
    Number_rabies,
    Number_malaria,
    Number_hiv,
	Number_tuberculosis,
	Number_smallpox,
	Number_cholera_cases
FROM
	infection_instances ii;
