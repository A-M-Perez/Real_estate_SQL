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

-- REPLICATE SAME ANALYSIS FOR 'Casa', ADJUSTING PARAMETERS WHERE NEEDED

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

	-- Check properties bigger than 1000m2, which can be considered significantly big houses. Compare property's average price to average price of all houses (by neighbourhood or city) to assess reasonability of size and price.
    SELECT 
		ap.province, 
        ap.neighbourhood_or_city, 
        ap.covered_area_m2, 
        FORMAT(ap.price,0) AS price,
        ap.avg_price_m2, 
		FORMAT(
			avg_by_neighbourhood_or_city.price_m2       
			,0) AS avg_neighbourhood_or_city,
		FORMAT(((ap.avg_price_m2 - avg_by_neighbourhood_or_city.price_m2) / ap.avg_price_m2) * 100,2) AS avg_price_var
    FROM 
		real_estate_arg.all_properties ap,
		(SELECT neighbourhood_or_city, AVG(avg_price_m2) AS price_m2
				FROM real_estate_arg.all_properties
				WHERE property_type = 'Casa'
				GROUP BY neighbourhood_or_city) AS avg_by_neighbourhood_or_city
    WHERE 
		property_type = 'Casa' AND 
        covered_area_m2 > 1000 AND
        ap.neighbourhood_or_city = avg_by_neighbourhood_or_city.neighbourhood_or_city
	ORDER BY covered_area_m2 DESC;

	-- Add an ID column to each property in the table
    ALTER TABLE real_estate_arg.all_properties
    ADD COLUMN property_id INT AUTO_INCREMENT PRIMARY KEY;
    
	-- Remove all records which absolute value variance from the average price benchmark for the neighbourhood or city is over 50% (10 records removed)
	    DELETE FROM real_estate_arg.all_properties
        WHERE property_id IN (
			SELECT property_id FROM (
				SELECT ap.property_id
				FROM 
				real_estate_arg.all_properties ap,
				(SELECT neighbourhood_or_city, AVG(avg_price_m2) AS price_m2
						FROM real_estate_arg.all_properties
						WHERE property_type = 'Casa'
						GROUP BY neighbourhood_or_city) AS avg_by_neighbourhood_or_city
				WHERE 
					property_type = 'Casa' AND 
					covered_area_m2 > 1000 AND
					ap.neighbourhood_or_city = avg_by_neighbourhood_or_city.neighbourhood_or_city
					AND ABS(((ap.avg_price_m2 - avg_by_neighbourhood_or_city.price_m2) / ap.avg_price_m2) * 100) > 50
                    ) AS t2
		);
  
	-- Visually check average price, total area, covered area and price per square meter of houses by provinces
    SELECT
		province,
        FORMAT(AVG(price),0) AS avg_price,
        FORMAT(AVG(total_area_m2),0) AS avg_total_area_m2,
        FORMAT(AVG(covered_area_m2),0) AS avg_covered_area_m2,
        FORMAT(AVG(avg_price_m2),0) AS avg_price_m2
	FROM real_estate_arg.all_properties
    WHERE property_type = 'Casa'
    GROUP BY province
    ORDER BY province ASC;

-- REPLICATE SAME ANALYSIS FOR 'PH', ADJUSTING PARAMETERS WHERE NEEDED

-- Look at 'PH' by size and price of the property, also considering the average price per square meter
SELECT province, neighbourhood_or_city, total_area_m2, covered_area_m2, FORMAT(price,2) AS price, avg_price_m2, price_currency
FROM real_estate_arg.all_properties
WHERE property_type = 'PH'
GROUP BY avg_price_m2
ORDER BY avg_price_m2 DESC;

	/*
    Segregate in 5 bins of average price per square meter:
		- Between $0 and $500
        - Between $500 and $1k
        - Between $1k and $2k
		- Between $2k and $3k
		- Over $3k
    */
	
    -- Add column to assign each record to one of the identified bins
    UPDATE real_estate_arg.all_properties
    SET bin = CASE
				WHEN avg_price_m2 >= 0 AND avg_price_m2 < 500 THEN '01. 0 to 500'
				WHEN avg_price_m2 >= 500 AND avg_price_m2 < 1000 THEN '02. 500 to 1k'
				WHEN avg_price_m2 >= 1000 AND avg_price_m2 < 2000 THEN '03. 1k to 2k'
                WHEN avg_price_m2 >= 2000 AND avg_price_m2 < 3000 THEN '04. 2k to 3k'
				WHEN avg_price_m2 >= 3000 THEN '05. over 3k'
				END
	WHERE property_type = 'PH';

	-- Check bins and occurrences
	SELECT bin, COUNT(bin)
    FROM real_estate_arg.all_properties
    WHERE property_type = 'PH'
    GROUP BY bin
    ORDER BY bin ASC;

	-- Remove records from the smallest bin with the biggest values (2 records removed)
    DELETE FROM real_estate_arg.all_properties
    WHERE property_type = 'PH' AND avg_price_m2 >= 3000;

	/*
    Check remaining smallest bin -'04. 2k to 3k'- with biggest values by province and neighbourhood or city, to assess reasonability of prices per location.
    Properties contained in the bin seem reasonable in price according to the neighbourhood. No need to remove.
    */
    SELECT province, neighbourhood_or_city, avg_price_m2, COUNT(property_type) AS number_of_properties
    FROM real_estate_arg.all_properties
    WHERE property_type = 'PH' AND bin = '04. 2k to 3k'
    GROUP BY province, neighbourhood_or_city
    ORDER BY avg_price_m2 DESC;

	/*
    Check next smallest bin -'01. 0 to 500'- with lowest values by province and neighbourhood or city, to assess reasonability of prices per location.
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
    WHERE property_type = 'PH' AND bin = '01. 0 to 500'
    GROUP BY province, neighbourhood_or_city
    ORDER BY avg_price_m2 ASC;

	/*
    Check total and covered area. 'PH' refers to apartments on ground floor, more similar to a house than to an apartment, where the total area is usually bigger than the the covered area due to open spaces.
    PH's with small covered areas compared to the total area, might be error inputs where common areas are being included in the total area for the specific property.
    */
    SELECT 
		property_id,
		province, 
        neighbourhood_or_city,
        total_area_m2, 
        covered_area_m2, 
        FORMAT(price,0) AS price, 
        FORMAT(covered_area_m2 / total_area_m2,2) AS percentage_covered_m2, 
        avg_price_m2
	FROM real_estate_arg.all_properties
    WHERE property_type = 'PH' AND (covered_area_m2 / total_area_m2) < 0.3
    ORDER BY (covered_area_m2 / total_area_m2) ASC;
    
    -- Remove item not reasonable in terms of data disclosed (1 record removed)
    DELETE FROM real_estate_arg.all_properties
    WHERE property_id = 34854;

	-- Check lowest, highest, and average values of properties by province
    SELECT 
		province,
        FORMAT(MIN(price),0) AS lowest_value,
        FORMAT(AVG(price),0) AS avg_value,
        FORMAT(MAX(price),0) AS highest_value
	FROM real_estate_arg.all_properties
    WHERE property_type = 'PH'
    GROUP BY province
    ORDER BY province ASC;

	-- Check properties with a price lower than $25k and an average price per square meter lower than $300, which is usually a really cheap value across the country
    SELECT property_id, province, neighbourhood_or_city, FORMAT(price,0) AS price, covered_area_m2, avg_price_m2
    FROM real_estate_arg.all_properties
    WHERE property_type = 'PH' AND price < 25000 AND avg_price_m2 < 300
    ORDER BY price ASC;
    
    -- Remove all records with a price lower than $25k and an average price per square meter of $200 (12 records removed)
    DELETE FROM real_estate_arg.all_properties
    WHERE property_type = 'PH' AND price < 25000 AND avg_price_m2 < 200;

	-- Check properties bigger than 400m2, which can be considered significantly big PHs. Compare property's average price to average price of all PHs (by neighbourhood or city) to assess reasonability of size and price.
    SELECT 
		ap.province, 
        ap.neighbourhood_or_city, 
        ap.covered_area_m2, 
        FORMAT(ap.price,0) AS price,
        ap.avg_price_m2, 
		FORMAT(
			avg_by_neighbourhood_or_city.price_m2       
			,0) AS avg_neighbourhood_or_city,
		FORMAT(((ap.avg_price_m2 - avg_by_neighbourhood_or_city.price_m2) / ap.avg_price_m2) * 100,2) AS avg_price_var
    FROM 
		real_estate_arg.all_properties ap,
		(SELECT neighbourhood_or_city, AVG(avg_price_m2) AS price_m2
				FROM real_estate_arg.all_properties
				WHERE property_type = 'PH'
				GROUP BY neighbourhood_or_city) AS avg_by_neighbourhood_or_city
    WHERE 
		property_type = 'PH' AND 
        covered_area_m2 > 400 AND
        ap.neighbourhood_or_city = avg_by_neighbourhood_or_city.neighbourhood_or_city
	ORDER BY covered_area_m2 DESC;
    
	-- Remove all records which absolute value variance from the average price benchmark for the neighbourhood or city is over 50% (9 records removed)
	    DELETE FROM real_estate_arg.all_properties
        WHERE property_id IN (
			SELECT property_id FROM (
				SELECT ap.property_id
				FROM 
				real_estate_arg.all_properties ap,
				(SELECT neighbourhood_or_city, AVG(avg_price_m2) AS price_m2
						FROM real_estate_arg.all_properties
						WHERE property_type = 'PH'
						GROUP BY neighbourhood_or_city) AS avg_by_neighbourhood_or_city
				WHERE 
					property_type = 'PH' AND 
					covered_area_m2 > 400 AND
					ap.neighbourhood_or_city = avg_by_neighbourhood_or_city.neighbourhood_or_city
					AND ABS(((ap.avg_price_m2 - avg_by_neighbourhood_or_city.price_m2) / ap.avg_price_m2) * 100) > 50
                    ) AS t2
		);
  
	-- Visually check average price, total area, covered area and price per square meter of PHs by provinces
    SELECT
		province,
        FORMAT(AVG(price),0) AS avg_price,
        FORMAT(AVG(total_area_m2),0) AS avg_total_area_m2,
        FORMAT(AVG(covered_area_m2),0) AS avg_covered_area_m2,
        FORMAT(AVG(avg_price_m2),0) AS avg_price_m2
	FROM real_estate_arg.all_properties
    WHERE property_type = 'PH'
    GROUP BY province
    ORDER BY province ASC;

-- Remove unused columns
ALTER TABLE real_estate_arg.all_properties
	DROP COLUMN bin,
	DROP COLUMN property_id;

/*
To perform some extra EDA, I have pulled the year 2020's -latest available- population information in Argentina by province.
Since data is not contemporary, this section is only aimed at applying JOINs while peforming EDA.
*/

-- Manually create and populate data for the year 2020 in Argentina
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

-- Visually check table
SELECT *
FROM real_estate_arg.population_and_km2_area
ORDER BY population DESC;

-- Add column with population density
ALTER TABLE real_estate_arg.population_and_km2_area
ADD COLUMN population_density INT;

-- Add values to the 'population_density' column (people per square kilometer)
UPDATE real_estate_arg.population_and_km2_area
SET population_density = (population / total_area_km2);

-- Visually check table
SELECT *
FROM real_estate_arg.population_and_km2_area
ORDER BY population_density DESC;

-- Check total population, area and density in Argentina. 'Antartida' is almost inhabited and therefore excluded from the agreggation.
SELECT 
	FORMAT(SUM(population),0) AS population, 
    FORMAT(SUM(total_area_km2),0) AS total_area_km2,
    FORMAT(SUM(population_density),0) AS population_density
FROM real_estate_arg.population_and_km2_area
WHERE province != 'Tierra del Fuego, Antartida e Islas del Atlantico Sur';

-- Check properties in the market by province and population
SELECT ap.province, FORMAT(p_a.population,0) AS population, FORMAT(COUNT(property_type),0) AS property_number
FROM real_estate_arg.all_properties ap
	JOIN real_estate_arg.population_and_km2_area p_a
		ON ap.province = p_a.province
GROUP BY province
ORDER BY province;

-- Check proportion of properties in the market and of population for each province, relative to each total
SELECT 
	ap.province,
	FORMAT((COUNT(ap.property_type) / properties_total.total) * 100,2) AS market_share,
    FORMAT((p_a.population / population_total.total) * 100,2) AS population_percentage
FROM 
	real_estate_arg.all_properties ap
		JOIN real_estate_arg.population_and_km2_area p_a
		ON ap.province = p_a.province,
	(SELECT COUNT(property_type) AS total
    FROM real_estate_arg.all_properties) AS properties_total,
	(SELECT SUM(population) AS total
    FROM real_estate_arg.population_and_km2_area) AS population_total
GROUP BY ap.province
ORDER BY ap.province ASC;

-- Check average total area of properties by province and the province's total area
SELECT
	ap.province,
    p_a.total_area_km2,
    AVG(ap.total_area_m2) AS avg_total_area_m2
FROM real_estate_arg.all_properties ap
	JOIN real_estate_arg.population_and_km2_area p_a
    ON ap.province = p_a.province
GROUP BY ap.province
ORDER BY p_a.total_area_km2 DESC, avg_total_area_m2 DESC;

#------------------------------- CREATING VIEWS -------------------------------

-- To show all apartments' information as well as the province's population
CREATE OR REPLACE VIEW apartments AS
	SELECT ap.*, p_a.population AS province_population
	FROM real_estate_arg.all_properties ap
		JOIN real_estate_arg.population_and_km2_area p_a
        ON ap.province = p_a.province
    WHERE property_type = 'Departamento';

SELECT * FROM apartments;

-- To show all properties which price is below market average and size is above market average, considering the property type and neighbourhood
CREATE OR REPLACE VIEW opportunities AS  
	SELECT ap.*
	FROM 
		real_estate_arg.all_properties ap,
		(SELECT 
			property_type, 
			neighbourhood_or_city, 
			AVG(price) AS avg_price_neighbourhood_or_city
		FROM real_estate_arg.all_properties
		GROUP BY property_type, neighbourhood_or_city) AS avg_prices,
		(SELECT
			property_type,
			neighbourhood_or_city,
			AVG(total_area_m2) AS avg_area_neighbourhood_or_city
		FROM real_estate_arg.all_properties
		GROUP BY property_type, neighbourhood_or_city) AS avg_area
	WHERE 
		(ap.property_type = avg_prices.property_type AND ap.property_type = avg_area.property_type)
		AND
		(ap.neighbourhood_or_city = avg_prices.neighbourhood_or_city AND ap.neighbourhood_or_city = avg_area.neighbourhood_or_city)
		AND
		ap.price < avg_prices.avg_price_neighbourhood_or_city
		AND
		ap.total_area_m2 > avg_area.avg_area_neighbourhood_or_city;
        
SELECT * FROM opportunities;

#------------------------------- CREATING A STORED PROCEDURE -------------------------------

# (same query as above)
-- To find opportunities in the market, where properties have a price that is below market average and a size that is above market average, considering the property type and neighbourhood
DELIMITER $$
CREATE PROCEDURE find_opportunities()
BEGIN
	SELECT ap.*
		FROM 
			real_estate_arg.all_properties ap,
			(SELECT 
				property_type, 
				neighbourhood_or_city, 
				AVG(price) AS avg_price_neighbourhood_or_city
			FROM real_estate_arg.all_properties
			GROUP BY property_type, neighbourhood_or_city) AS avg_prices,
			(SELECT
				property_type,
				neighbourhood_or_city,
				AVG(total_area_m2) AS avg_area_neighbourhood_or_city
			FROM real_estate_arg.all_properties
			GROUP BY property_type, neighbourhood_or_city) AS avg_area
		WHERE 
			(ap.property_type = avg_prices.property_type AND ap.property_type = avg_area.property_type)
			AND
			(ap.neighbourhood_or_city = avg_prices.neighbourhood_or_city AND ap.neighbourhood_or_city = avg_area.neighbourhood_or_city)
			AND
			ap.price < avg_prices.avg_price_neighbourhood_or_city
			AND
			ap.total_area_m2 > avg_area.avg_area_neighbourhood_or_city;
END$$
DELIMITER ;

CALL real_estate_arg.find_opportunities();