-- Visually check data
SELECT *
FROM real_estate_arg.all_properties;

/*
Check number of property types and their share in the total market
	- 'Departamento' 50.54%
    - 'Casa' 32.36%
    - 'PH' 10.87%
These 3 property types add up to 93.77% of the total market share
*/
SELECT 
	property_type,
    COUNT(property_type) AS number_of_properties, 
    ROUND(
		(COUNT(t1.property_type) / t2.total) * 100,
         2) AS percentage_of_total
FROM real_estate_arg.all_properties AS t1,
	(SELECT COUNT(*) AS total
    FROM real_estate_arg.all_properties) AS t2
GROUP BY property_type
ORDER BY (COUNT(t1.property_type) / t2.total) * 100 DESC;

-- Check the average price of property types -only including the top 3 market share properties- by province
SELECT 
	province, 
    property_type, 
    FORMAT(AVG(price),2) AS avg_usd_price
FROM real_estate_arg.all_properties
WHERE property_type = 'Departamento' OR property_type = 'Casa'OR property_type = 'PH'
	AND price_currency = 'USD'
GROUP BY province, property_type
ORDER BY province, property_type ASC;

-- Check the average price of property types and the average price per square meter, making it visually accessible to compare between provinces -only top 3 market share properties-
SELECT
	province, 
    property_type, 
    FORMAT(AVG(price),2) AS avg_usd_price,
    FORMAT(SUM(price) / SUM(total_area_m2),2) AS avg_price_m2
FROM real_estate_arg.all_properties
WHERE property_type = 'Departamento' OR property_type = 'Casa'OR property_type = 'PH'
	AND price_currency = 'USD'
GROUP BY province, property_type
ORDER BY property_type, province  ASC;

-- Add column for average price per square meter
ALTER TABLE real_estate_arg.all_properties
ADD COLUMN avg_price_m2 DECIMAL;

-- Calculate average price per square meter values
UPDATE real_estate_arg.all_properties
SET avg_price_m2 = price / total_area_m2;

-- Visually check values
SELECT total_area_m2, price, avg_price_m2
FROM real_estate_arg.all_properties;

-- Individually check property types 'Departamento', 'Casa' and 'PH' to identify outliers

-- Look at 'Departamento' by size and price of the property, also considering the average price per square meter
SELECT province, neighbourhood_or_city, total_area_m2, covered_area_m2, FORMAT(price,2), FORMAT(avg_price_m2,2), price_currency
FROM real_estate_arg.all_properties
WHERE property_type = 'Departamento'
GROUP BY avg_price_m2
ORDER BY avg_price_m2 DESC;

	/*
    Segregate in 5 bins of average price per square meter:
		- Between $0 and $0.5k
        - Between $0.5k and $1k
        - Between $1k and $5k
		- Between $5k and $10k
		- Over $10k
    */
	
    -- Add column to assign each record to one of the identified bins
    ALTER TABLE real_estate_arg.all_properties
    ADD COLUMN bin VARCHAR(255);
    
    UPDATE real_estate_arg.all_properties
    SET bin = CASE
				WHEN avg_price_m2 >= 0 AND avg_price_m2 < 500 THEN '01. 0 to 0.5k'
				WHEN avg_price_m2 >= 500 AND avg_price_m2 < 1000 THEN '02. 0.5k to 1k'
				WHEN avg_price_m2 >= 1000 AND avg_price_m2 < 5000 THEN '03. 1k to 5k'
                WHEN avg_price_m2 >= 5000 AND avg_price_m2 < 10000 THEN '04. 5k to 10k'
				WHEN avg_price_m2 >= 10000 THEN '05. over 10k'
				END
	WHERE property_type = 'Departamento';

	-- Check bins and occurrences
	SELECT bin, COUNT(bin)
    FROM real_estate_arg.all_properties
    WHERE property_type = 'Departamento'
    GROUP BY bin
    ORDER BY bin ASC;

	-- Remove records from the smallest bin with the biggest values (16 records removed)
    DELETE FROM real_estate_arg.all_properties
    WHERE property_type = 'Departamento' AND avg_price_m2 >= 10000;

	/*
    Check remaining smallest bin -'04. 5k to 10k'- with biggest values by province and neighbourhood or city, to assess reasonability of prices per location.
    Properties contained in the bin seem reasonable in price according to the neighbourhood. No need to remove.
    */
    SELECT province, neighbourhood_or_city, FORMAT(avg_price_m2,0), COUNT(property_type) AS number_of_properties
    FROM real_estate_arg.all_properties
    WHERE property_type = 'Departamento' AND bin = '04. 5k to 10k'
    GROUP BY province, neighbourhood_or_city
    ORDER BY avg_price_m2 DESC;

	/*
    Check next remaining smallest bin -'01. 0 to 0.5k'- with biggest values by province and neighbourhood or city, to assess reasonability of prices per location.
    Low average prices per square meter do not seem reasonable. Will assess more data related to the size of the properties to determine whether records are outliers that need to be corrected/removed.
    */
	SELECT 
		province, 
		neighbourhood_or_city, 
        FORMAT(total_area_m2,0) AS total_area_m2, 
        FORMAT(price,0) AS price, 
        FORMAT(avg_price_m2,0) AS avg_price_m2, 
        COUNT(property_type) AS number_of_properties
    FROM real_estate_arg.all_properties
    WHERE property_type = 'Departamento' AND bin = '01. 0 to 0.5k'
    GROUP BY province, neighbourhood_or_city
    ORDER BY avg_price_m2 ASC;

	/*
    Check total and covered area. 'Departamento' refers to apartments, where in most cases the total area should match the covered area.
    Differences can be found due to errors when inputting the data, balconies -and similar areas-, or Real Estate Agents advertising common areas as part of the total area of the apartment.
    */
    SELECT 
		province, 
        neighbourhood_or_city,
        total_area_m2, 
        covered_area_m2, 
        FORMAT(price,0) AS price, 
        FORMAT(covered_area_m2 / total_area_m2,2) AS percentage_covered_m2, 
        avg_price_m2
	FROM real_estate_arg.all_properties
    WHERE property_type = 'Departamento' AND avg_price_m2 < 500
    ORDER BY (covered_area_m2 / total_area_m2) ASC;

	-- Check average price per square meter for apartments where the covered area matches the total area
    SELECT province, FORMAT(AVG(avg_price_m2),0) AS avg_price
    FROM real_estate_arg.all_properties
    WHERE property_type = 'Departamento' AND avg_price_m2 < 500 AND total_area_m2 = covered_area_m2
    GROUP BY province
    ORDER BY AVG(avg_price_m2) ASC;

	-- Remove all apartments with an average price per square meter lower than $300 (131 records removed)
    DELETE FROM real_estate_arg.all_properties
    WHERE property_type = 'Departamento' AND avg_price_m2 < 300; 

	-- Check lowest, highest, and average values of properties by province
    SELECT 
		province,
        FORMAT(MIN(price),0) AS lowest_value,
        FORMAT(AVG(price),0) AS avg_value,
        FORMAT(MAX(price),0) AS highest_value
	FROM real_estate_arg.all_properties
    WHERE property_type = 'Departamento'
    GROUP BY province
    ORDER BY province ASC;

	-- Check properties smaller than 17m2, which are usually the smallest apartments
    SELECT province, neighbourhood_or_city, covered_area_m2, FORMAT(price,0) AS price
    FROM real_estate_arg.all_properties
    WHERE property_type = 'Departamento' AND covered_area_m2 <= 17
	ORDER BY covered_area_m2 ASC;

	-- Remove properties with a covered area smaller than 14m2 (5 records removed)
    DELETE FROM real_estate_arg.all_properties
    WHERE property_type = 'Departamento' AND covered_area_m2 < 14;

	-- Check properties with a price lower than $30k, which is usually a really cheap value across the country
    SELECT province, neighbourhood_or_city, FORMAT(price,0) AS price, covered_area_m2, avg_price_m2
    FROM real_estate_arg.all_properties
    WHERE property_type = 'Departamento' AND price < 30000
    ORDER BY price ASC;

	-- Check properties bigger than 300m2, which are usually the biggest apartments. Compare property's average price to average price of all apartments to assess reasonability of size and price based on neighbourhood or city.
    SELECT 
		province, 
        neighbourhood_or_city, 
        covered_area_m2, 
        FORMAT(price,0) AS price, avg_price_m2, 
		FORMAT(
			(SELECT AVG(avg_price_m2)
			FROM real_estate_arg.all_properties
			WHERE property_type = 'Departamento'),0) AS avg_general
    FROM real_estate_arg.all_properties
    WHERE property_type = 'Departamento' AND covered_area_m2 > 300
	ORDER BY covered_area_m2 DESC;

	-- Visually check average price, total area, covered area and price per square meter of apartments by provinces
    SELECT
		province,
        FORMAT(AVG(price),0) AS avg_price,
        FORMAT(AVG(total_area_m2),0) AS avg_total_area_m2,
        FORMAT(AVG(covered_area_m2),0) AS avg_covered_area_m2,
        FORMAT(AVG(avg_price_m2),0) AS avg_price_m2
	FROM real_estate_arg.all_properties
    WHERE property_type = 'Departamento'
    GROUP BY province
    ORDER BY province ASC;

-- REPLICATE SAME ANALYSIS FOR 'CASA', ADJUSTING PARAMETERS WHERE NEEDED

-- Look at 'Casa' by size and price of the property, also considering the average price per square meter
SELECT province, neighbourhood_or_city, total_area_m2, covered_area_m2, FORMAT(price,2) AS price, avg_price_m2, price_currency
FROM real_estate_arg.all_properties
WHERE property_type = 'Casa'
GROUP BY avg_price_m2
ORDER BY avg_price_m2 DESC;

	/*
    Segregate in 5 bins of average price per square meter:
		- Between $0 and $1k
        - Between $1k and $5k
        - Between $5k and $10k
		- Between $10k and $15k
		- Over $15k
    */
	
    -- Add column to assign each record to one of the identified bins
    UPDATE real_estate_arg.all_properties
    SET bin = CASE
				WHEN avg_price_m2 >= 0 AND avg_price_m2 < 1000 THEN '01. 0 to 1k'
				WHEN avg_price_m2 >= 1000 AND avg_price_m2 < 5000 THEN '02. 1k to 5k'
				WHEN avg_price_m2 >= 5000 AND avg_price_m2 < 10000 THEN '03. 5k to 10k'
                WHEN avg_price_m2 >= 10000 AND avg_price_m2 < 15000 THEN '04. 10k to 15k'
				WHEN avg_price_m2 >= 15000 THEN '05. over 15k'
				END
	WHERE property_type = 'Casa';

	-- Check bins and occurrences
	SELECT bin, COUNT(bin)
    FROM real_estate_arg.all_properties
    WHERE property_type = 'Casa'
    GROUP BY bin
    ORDER BY bin ASC;

	-- Remove records from the smallest bin with the biggest values (6 records removed)
    DELETE FROM real_estate_arg.all_properties
    WHERE property_type = 'Casa' AND avg_price_m2 >= 5000;

	/*
    Check remaining smallest bin -'02. 1k to 5k'- with biggest values by province and neighbourhood or city, to assess reasonability of prices per location.
    Properties contained in the bin seem reasonable in price according to the neighbourhood. No need to remove.
    */
    SELECT province, neighbourhood_or_city, avg_price_m2, COUNT(property_type) AS number_of_properties
    FROM real_estate_arg.all_properties
    WHERE property_type = 'Casa' AND bin = '02. 1k to 5k'
    GROUP BY province, neighbourhood_or_city
    ORDER BY avg_price_m2 DESC;

	/*
    Check biggest bin -'01. 0 to 1k'- with lowest values by province and neighbourhood or city, to assess reasonability of prices per location.
    Low average prices per square meter do not seem reasonable. Will assess more data related to the size of the properties to determine whether records are outliers that need to be corrected/removed.
    */
	SELECT 
		province, 
		neighbourhood_or_city, 
        FORMAT(total_area_m2,0) AS total_area_m2, 
        FORMAT(price,0) AS price, 
        avg_price_m2, 
        COUNT(property_type) AS number_of_properties
    FROM real_estate_arg.all_properties
    WHERE property_type = 'Casa' AND bin = '01. 0 to 1k'
    GROUP BY province, neighbourhood_or_city
    ORDER BY avg_price_m2 ASC;

	/*
    Check total and covered area. 'Casa' refers to houses, where the total area is usually bigger than the the covered area due to open spaces.
    Houses with small covered areas compared to the total area, might be error inputs of 'land' properties without an actual house built in.
    */
    SELECT 
		province, 
        neighbourhood_or_city,
        total_area_m2, 
        covered_area_m2, 
        FORMAT(price,0) AS price, 
        FORMAT(covered_area_m2 / total_area_m2,2) AS percentage_covered_m2, 
        avg_price_m2
	FROM real_estate_arg.all_properties
    WHERE property_type = 'Casa' AND covered_area_m2 < 20
    ORDER BY (covered_area_m2 / total_area_m2) ASC;

	-- Remove all houses with a covered area lower than 20 (25 records removed)
    DELETE FROM real_estate_arg.all_properties
    WHERE property_type = 'Casa' AND covered_area_m2 < 20; 

	-- Check lowest, highest, and average values of properties by province
    SELECT 
		province,
        FORMAT(MIN(price),0) AS lowest_value,
        FORMAT(AVG(price),0) AS avg_value,
        FORMAT(MAX(price),0) AS highest_value
	FROM real_estate_arg.all_properties
    WHERE property_type = 'Casa'
    GROUP BY province
    ORDER BY province ASC;

	-- Check properties smaller than 20m2, which are usually the smallest Houses
    SELECT province, neighbourhood_or_city, covered_area_m2, FORMAT(price,0) AS price
    FROM real_estate_arg.all_properties
    WHERE property_type = 'Casa' AND covered_area_m2 < 20
	ORDER BY covered_area_m2 ASC;

	-- Check properties with a price lower than $30k and an average price per square meter lower than $500, which is usually a really cheap value across the country
    SELECT province, neighbourhood_or_city, FORMAT(price,0) AS price, covered_area_m2, avg_price_m2
    FROM real_estate_arg.all_properties
    WHERE property_type = 'Casa' AND price < 30000 AND avg_price_m2 < 500
    ORDER BY price ASC;
    
    -- Remove all records per search above (190 records removed)
    DELETE FROM real_estate_arg.all_properties
    WHERE property_type = 'Casa' AND price < 30000 AND avg_price_m2 < 500;

	-- Check properties bigger than 1000m2, which are really big houses. Compare property's average price to average price of all houses to assess reasonability of size and price based on neighbourhood or city.
    SELECT 
		province, 
        neighbourhood_or_city, 
        covered_area_m2, 
        FORMAT(price,0) AS price, avg_price_m2, 
		FORMAT(
			(SELECT AVG(avg_price_m2)
			FROM real_estate_arg.all_properties
			WHERE property_type = 'Casa'),0) AS avg_general
    FROM real_estate_arg.all_properties
    WHERE property_type = 'Casa' AND covered_area_m2 > 1000
	ORDER BY covered_area_m2 DESC;

	-- Visually check average price, total area, covered area and price per square meter of apartments by provinces
    SELECT
		province,
        FORMAT(AVG(price),0) AS avg_price,
        FORMAT(AVG(total_area_m2),0) AS avg_total_area_m2,
        FORMAT(AVG(covered_area_m2),0) AS avg_covered_area_m2,
        FORMAT(AVG(avg_price_m2),0) AS avg_price_m2
	FROM real_estate_arg.all_properties
    WHERE property_type = 'Departamento'
    GROUP BY province
    ORDER BY province ASC;


-- real_estate_arg.all_properties























CREATE TABLE population_and_km2_area (
	province VARCHAR(255),
    population INT, 
    total_area_km2 DECIMAL
    );
    
INSERT INTO population_and_km2_area
VALUES 
	('Capital Federal', 3075646, 205.9),
    ('Buenos Aires', 17541141, 305907.4),
    ('Catamarca', 415438, 101486.1),
    ('Chaco', 1204541, 99763.3),
    ('Chubut', 618994, 224302.3),
    ('Cordoba', 3760450, 164707.8),
    ('Corrientes', 1120801, 89123.3),
    ('Entre Rios', 1385961, 78383.7),
    ('Formosa', 605193, 75488.3),
    ('Jujuy', 770881, 53244.2),
    ('La Pampa', 358428, 143492.5),
    ('La Rioja', 393531, 91493.7),
    ('Mendoza', 1990338, 149069.2),
    ('Misiones', 1261294, 29911.4),
    ('Neuquen', 664057, 94422),
    ('Rio Negro', 747610, 202168.6),
    ('Salta', 1424397, 155340.5),
    ('San Juan', 781217, 88296.2),
    ('San Luis', 508328, 75347.1),
    ('Santa Cruz', 365698, 244457.5),
    ('Santa Fe', 3536418, 133249.1),
    ('Santiago Del Estero', 978313, 136934.3),
    ('Tierra del Fuego, Antartida e Islas del Atlantico Sur', 173715, 910324.4),
    ('Tucuman', 1694656, 22592.1);

SELECT *
FROM real_estate_arg.population_and_km2_area;