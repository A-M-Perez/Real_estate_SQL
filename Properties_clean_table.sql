#---------------------------------------------------1----------------------------------------------------------------------------
-- Create new Database
CREATE DATABASE IF NOT EXISTS  real_estate_arg;
USE real_estate_arg;

#---------------------------------------------------2----------------------------------------------------------------------------

/*
Data manually imported using MySQL "Table Data Import Wizard".
Due to size, import was performed in two stages (tables "properties" & "properties2") and then unified under a new table named "all_properties".
Step can be skipped if properly imported in one table, or extended if more than 2 tables are required for import.
*/
CREATE TABLE all_properties AS
	SELECT *
    FROM real_estate_arg.properties
		UNION ALL
			SELECT *
            FROM real_estate_arg.properties2;

-- Visually check the data in the new table
SELECT *
FROM real_estate_arg.all_properties;

-- Verify all records have been imported (should return 42.940)
SELECT COUNT(property_type)
FROM real_estate_arg.all_properties;

/* 
After confirming all data is imported in one table, drop unnecessary (duplicate) tables.
Step can be skipped if properly imported in one table, or extended if more than 2 tables were required for import.
*/
DROP TABLE real_estate_arg.properties;
DROP TABLE real_estate_arg.properties2;

-- Save checkpoint with imported data
COMMIT;

#---------------------------------------------------3----------------------------------------------------------------------------

-- Check data types of each column
SHOW FIELDS
FROM real_estate_arg.all_properties;

#--------------------------------------------------3.1---------------------------------------------------------------------------

/* 
Check the distinct type of properties available and the number of records per each of them, ordering the data with the highest number of properties in market at the top.
*/
SELECT property_type, COUNT(property_type) AS number_of_properties
FROM real_estate_arg.all_properties
GROUP BY property_type
ORDER BY number_of_properties DESC;

-- Correct text format issue for properties with the name "Galp—n"
UPDATE real_estate_arg.all_properties
SET property_type = REPLACE(property_type, "Galp—n", "Galpon");

-- Check for NULL values in property_type
SELECT property_type, COUNT(property_type) AS number_of_properties
FROM real_estate_arg.all_properties
WHERE property_type = ''
GROUP BY property_type
ORDER BY number_of_properties DESC;

-- Save checkpoint after confirming "property_type" has valid values
COMMIT;

#--------------------------------------------------3.2---------------------------------------------------------------------------

/* 
Check locations available and the number of records per each of them, ordering the data with the highest number of properties per location in the market at the top.
*/
SELECT location, COUNT(location) AS number_of_locations
FROM real_estate_arg.all_properties
GROUP BY location
ORDER BY number_of_locations DESC;

-- Check the number of different locations
SELECT COUNT(DISTINCT(location))
FROM real_estate_arg.all_properties;

-- Check for NULL values in location
SELECT location, COUNT(location) AS number_of_locations
FROM real_estate_arg.all_properties
WHERE location = ''
GROUP BY location
ORDER BY number_of_locations DESC;

-- Delete from table, all null values in location (260 records)
DELETE FROM real_estate_arg.all_properties
WHERE location = '';

-- Add the 'province' column to be populated from the 'location' data
ALTER TABLE real_estate_arg.all_properties
ADD COLUMN province VARCHAR(255);

	-- Extract the province for each of the locations (after the last comma)
	UPDATE real_estate_arg.all_properties
	SET province = TRIM(SUBSTRING_INDEX(location,',',-1));

	-- Check provinces' names and number of records per each province
	SELECT DISTINCT(province) AS province_name, COUNT(province)
	FROM real_estate_arg.all_properties
    GROUP BY province_name
    ORDER BY province_name ASC;

-- Since too many locations have a text and number that is invalid, delete these specific strings from the province name
UPDATE real_estate_arg.all_properties
SET province = REGEXP_REPLACE(
	REGEXP_REPLACE(
		REGEXP_REPLACE(
			REGEXP_REPLACE(
            province,
            'solicitar precio [0-9]+',
            ''),
		'Solicitar precio',
		''),
	'[0-9]+',
	''),
'USD',
'');

-- Trim text to standardize provinces' names
UPDATE real_estate_arg.all_properties
SET province = TRIM(province);

-- Check provinces' names and number of records per each province
	SELECT DISTINCT(province) AS province_name, COUNT(province) AS number_of_properties
	FROM real_estate_arg.all_properties
    GROUP BY province_name
    ORDER BY number_of_properties DESC;
    
-- Manually create a table including Argentinean provinces, to check remaining provinces in 'all_properties' table are valid
CREATE TABLE arg_provinces(
	province_name VARCHAR(255)
	);

	INSERT INTO real_estate_arg.arg_provinces(province_namename) VALUES
		('Buenos Aires'),
		('Capital Federal'),
		('Catamarca'),
		('Chaco'),
		('Chubut'),
		('Cordoba'),
		('Corrientes'),
		('Entre Rios'),
		('Formosa'),
		('Jujuy'),
		('La Pampa'),
		('La Rioja'),
		('Mendoza'),
		('Misiones'),
		('Neuquen'),
		('Rio Negro'),
		('Salta'),
		('San Juan'),
		('San Luis'),
		('Santa Cruz'),
		('Santa Fe'),
		('Santiago del Estero'),
		('Tierra del Fuego, Antartida e Islas del Atlantico Sur'),
		('Tucuman')
        ;
    
		-- Visually check values
		SELECT * FROM real_estate_arg.arg_provinces;

-- Compare provinces in 'all_properties' against 'arg_provinces' to validate data and check number of records per province
SELECT allp.province, argp.province_name, COUNT(allp.province) AS number_of_records
FROM real_estate_arg.all_properties allp
	JOIN real_estate_arg.arg_provinces argp
		ON allp.province = argp.province_name
GROUP BY allp.province
ORDER BY number_of_records DESC;

-- Check non-matching provinces between 'all_properties' and 'arg_provinces' and show location
SELECT allp.location, allp.province, argp.province_name, COUNT(allp.province) AS number_of_records
FROM real_estate_arg.all_properties allp
	LEFT OUTER JOIN real_estate_arg.arg_provinces argp
		ON allp.province = argp.province_name
WHERE argp.province_name IS NULL
GROUP BY allp.location
ORDER BY number_of_records DESC;

/* 
Correct identifiable records with the corresponding province
Rio Negro (264 records 'Bariloche' + 129 records 'Cipolleti' + 129 records 'General Roca')
Neuquen (485 records + 108 records 'Confluencia' + 54 records 'San Martin De Los Andes')
Cordoba (1689 records + 130 records 'Carlos Paz' + 265 records 'Colon')
Buenos Aires (116 records 'Pilar Del Este')
*/
	UPDATE real_estate_arg.all_properties
	SET province = 'Rio Negro'
	WHERE 
		LOCATE ('Bariloche', location) OR 
        LOCATE ('Cipolletti', location) OR
        LOCATE ('General Roca', location);

	UPDATE real_estate_arg.all_properties
	SET province = 'Neuquen'
	WHERE LOCATE ('Neuquen', location) OR
    LOCATE ('Confluencia', location) OR
    LOCATE ('San Martin De Los Andes', location);

	UPDATE real_estate_arg.all_properties
	SET province = 'Cordoba'
	WHERE 
		LOCATE ('Cordoba', location) OR
        LOCATE ('Carlos Paz', location) OR
        LOCATE (', Colon', location);

	UPDATE real_estate_arg.all_properties
	SET province = 'Buenos Aires'
	WHERE 
		LOCATE ('Pilar Del Este', location);

-- Remove remaining records not identifiable within a known province (1851 records)
DELETE allp FROM real_estate_arg.all_properties allp
	LEFT OUTER JOIN real_estate_arg.arg_provinces argp
	ON allp.province = argp.province_name
WHERE argp.province_name IS NULL;

SELECT DISTINCT(province)
FROM real_estate_arg.all_properties;

-- Save checkpoint with 'province' column cleaned
COMMIT;

-- Add the 'neighbourhood_or_city' column to be populated from the 'location' data
ALTER TABLE real_estate_arg.all_properties
ADD COLUMN neighbourhood_or_city VARCHAR(255);

	-- Extract the neighbourhood or city for each of the locations (between the last 2 commas)
	UPDATE real_estate_arg.all_properties
	SET neighbourhood_or_city = TRIM(
									SUBSTRING_INDEX(
										SUBSTRING_INDEX(
											location,',',-2),
										',', 1)
									);

-- Visually check neighbourhood or city names
SELECT DISTINCT(neighbourhood_or_city), province, COUNT(neighbourhood_or_city)
FROM  real_estate_arg.all_properties
GROUP BY neighbourhood_or_city
ORDER BY COUNT(neighbourhood_or_city) DESC;
 
 -- Names seem to have invalid data, therefore check only neighbourhood or city names
 SELECT DISTINCT(neighbourhood_or_city)
 FROM  real_estate_arg.all_properties
 ORDER BY neighbourhood_or_city ASC;
 
 -- Check neighbourhood or city names that contain numbers or odd text
 SELECT DISTINCT(neighbourhood_or_city)
 FROM  real_estate_arg.all_properties
 WHERE 
	neighbourhood_or_city REGEXP '[0-9]+' OR 
    LOCATE ('solicitar precio', neighbourhood_or_city)
 ORDER BY neighbourhood_or_city ASC;
 
 -- Manually replace invalid digits and text in the neighbourhood or city names
 UPDATE real_estate_arg.all_properties
 SET
	neighbourhood_or_city = REPLACE(
								REPLACE(
									REPLACE(
										REPLACE(
											REPLACE(
												REPLACE(
													neighbourhood_or_city,
													'600',''),
												'100',''),
											'1600',''),
										'Solicitar precio 299',''),
									'500',''),
                                '0','');
 
 -- Check for blank values as the neighbourhood (no blanks)
SELECT neighbourhood_or_city, COUNT(neighbourhood_or_city)
FROM real_estate_arg.all_properties
WHERE neighbourhood_or_city = '';
 
-- Save checkpoint with 'neighbourhood_or_city' column cleaned
COMMIT;

#--------------------------------------------------3.3---------------------------------------------------------------------------

-- Check price data and its ocurrence, currently formatted as text, in descending order, to see if the field contains letters
SELECT price, COUNT(price)
FROM real_estate_arg.all_properties
GROUP BY price
ORDER BY price DESC;

-- Check provinces and neighbourhoods or cities where the price is not available, and the percent of these properties in the total number of properties for that neighbourhood or city
SELECT 
	neighbourhood_or_city,
	province,
	SUM(IF(price='Solicitar',1,0)) AS properties_without_price, 
	COUNT(price) AS properties_per_neighbourhood_or_city, 
	((SUM(IF(price='Solicitar',1,0)) / COUNT(price))*100) AS percent_without_price
FROM real_estate_arg.all_properties
GROUP BY neighbourhood_or_city
ORDER BY percent_without_price DESC;

-- Remove properties without a price, since price is one of the main features needed in subsequent analyses
DELETE FROM real_estate_arg.all_properties
WHERE price = 'Solicitar';

-- Format column as number, using BIGINT due to values out of range
ALTER TABLE real_estate_arg.all_properties
MODIFY COLUMN price BIGINT;

-- Check biggest values, their currency and property type
SELECT price, price_currency, COUNT(price), property_type
FROM real_estate_arg.all_properties
GROUP BY price
ORDER BY price DESC;

/*
Several values are measured in Argentinean pesos (ARS) and not United States Dollars (USD).
It is very unusual to see properties expressed in ARS, since the market is mainly managed in USD.
Check percentage of properties expressed in ARS by neighbourhood/city and province, to understand if droping these values would remove entire geographic sectors from the dataset.
*/
SELECT
	province,
    neighbourhood_or_city,
    (SUM(IF(price_currency='ARS',1,0)) / COUNT(price_currency)) * 100 AS ars_percent,
    (SUM(IF(price_currency='USD',1,0)) / COUNT(price_currency)) * 100 AS usd_percent,
    SUM(IF(price_currency <> 'USD' AND price_currency <> 'ARS',1,0)) AS unidentified_currency
FROM real_estate_arg.all_properties
GROUP BY neighbourhood_or_city
ORDER BY ars_percent DESC;

-- Delete properties not expressed in USD (3 locations)
DELETE FROM real_estate_arg.all_properties
WHERE price_currency = 'ARS';

-- Validate properties are only expressed in USD
SELECT price_currency, COUNT(price_currency)
FROM real_estate_arg.all_properties
GROUP BY price_currency;

-- With smaller price values expressed in USD, format column as INT instead of BIGINT
ALTER TABLE real_estate_arg.all_properties
MODIFY COLUMN price INT;

-- Save checkpoint with 'price' and 'price_currency' columns cleaned
COMMIT;

#--------------------------------------------------3.4---------------------------------------------------------------------------

-- Check values for total area in m2, originally formatted as text, ordering in descending order to validate it does not contain non-numeric values
SELECT total_area_m2
FROM real_estate_arg.all_properties
GROUP BY total_area_m2
ORDER BY total_area_m2 DESC;

-- Format total area column as number
ALTER TABLE real_estate_arg.all_properties
MODIFY COLUMN total_area_m2 INT;

-- Visually check types of properties and the number of them by total area in m2
SELECT total_area_m2, property_type, COUNT(total_area_m2)
FROM real_estate_arg.all_properties
GROUP BY total_area_m2
ORDER BY total_area_m2 DESC;



# real_estate_arg.
# real_estate_arg.all_properties

-- SELECT location, neighbourhood_or_province, province, COUNT(location)
-- FROM real_estate_arg.all_properties
-- GROUP BY location;