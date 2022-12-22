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
Check the distinct type of properties available and the number of records per each of them, ordering the data with the highest number of properties in the market at the top.
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

-- Delete all null values -in location- from the table (260 records)
DELETE FROM real_estate_arg.all_properties
WHERE location = '' OR location IS NULL;

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

-- Visually check list of provinces
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
													REPLACE(
														neighbourhood_or_city,
														'600',''),
													'100',''),
												'1600',''),
											'Solicitar precio 299',''),
										'500',''),
									'0',''),
								'1','');
 
 -- Check for blank values as the neighbourhood (no blanks)
SELECT neighbourhood_or_city, COUNT(neighbourhood_or_city)
FROM real_estate_arg.all_properties
WHERE neighbourhood_or_city = '';
 
-- Save checkpoint with 'neighbourhood_or_city' column cleaned
COMMIT;

-- Delete the 'location' column with no further use in the dataset
ALTER TABLE real_estate_arg.all_properties
DROP COLUMN location;

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

-- Remove properties without a price, since price is one of the main features needed in subsequent analyses (1795 records)
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

-- Delete properties not expressed in USD (3 locations - 205 records)
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

-- Check for null values in total area by type of property
SELECT property_type, total_area_m2, COUNT(total_area_m2)
FROM real_estate_arg.all_properties
WHERE total_area_m2 = '' OR total_area_m2 IS NULL
ORDER BY property_type ASC;

-- Format total area column as number
ALTER TABLE real_estate_arg.all_properties
MODIFY COLUMN total_area_m2 INT;

-- Save checkpoint with 'total_area_m2' column cleaned
COMMIT;

#--------------------------------------------------3.5---------------------------------------------------------------------------

-- Check values for covered area in m2, originally formatted as text, ordering in descending order to validate it does not contain non-numeric values
SELECT covered_area_m2
FROM real_estate_arg.all_properties
GROUP BY covered_area_m2
ORDER BY covered_area_m2 DESC;

-- Check the number of null values for covered area, analyzing the property type and total area
SELECT property_type, total_area_m2, covered_area_m2, COUNT(property_type)
FROM real_estate_arg.all_properties
WHERE covered_area_m2 = '' OR covered_area_m2 IS NULL
GROUP BY property_type
ORDER BY property_type ASC;

-- Check for individual values to assess data
SELECT property_type, total_area_m2, covered_area_m2, price
FROM real_estate_arg.all_properties
WHERE covered_area_m2 = '' OR covered_area_m2 IS NULL
ORDER BY property_type ASC;

/*
'Chacra' refers mainly to land, therefore, a safe assumption is that the total_area_m2 is uncovered.
Check other 'Chacra' values to understand what their covered_area_m2 is.
*/
SELECT property_type, province, total_area_m2, covered_area_m2
FROM real_estate_arg.all_properties
WHERE property_type = 'Chacra'
ORDER BY province;

/*
Assumption: 'Chacra' properties default to 1 when no having no covered area.
Default covered area with value 0 or '' to value 1.
*/
UPDATE real_estate_arg.all_properties
SET covered_area_m2 = 1
WHERE property_type = 'Chacra' AND covered_area_m2 = 0;

-- Remove remaining blank records
DELETE FROM real_estate_arg.all_properties
WHERE covered_area_m2 = '' OR covered_area_m2 IS NULL;

-- Format covered area column as number
ALTER TABLE real_estate_arg.all_properties
MODIFY COLUMN covered_area_m2 INT;

-- Save checkpoint with 'covered_area_m2' column cleaned
COMMIT;

#--------------------------------------------------3.6---------------------------------------------------------------------------

-- Check values for number of rooms, originally formatted as text, ordering in descending order to validate it does not contain non-numeric values
SELECT room_number
FROM real_estate_arg.all_properties
GROUP BY room_number
ORDER BY room_number DESC;

-- Trim values
UPDATE real_estate_arg.all_properties
SET room_number = TRIM(room_number);

-- Check for number of null values
SELECT room_number, COUNT(room_number)
FROM real_estate_arg.all_properties
WHERE room_number = 0 OR room_number = '' OR room_number IS NULL;

-- Check for number of null values by type of property
SELECT property_type, room_number, COUNT(room_number)
FROM real_estate_arg.all_properties
WHERE room_number = 0 OR room_number = '' OR room_number IS NULL
GROUP BY property_type
ORDER BY COUNT(room_number) DESC;

-- Check if properties with no number of rooms, have a covered area
SELECT property_type, COUNT(covered_area_m2), COUNT(room_number)
FROM real_estate_arg.all_properties
WHERE room_number = 0
GROUP BY property_type
ORDER BY property_type;

/*
Assumption: All properties with covered area will have at least 1 room.
Default blank records to 1 in number of rooms.
*/
UPDATE real_estate_arg.all_properties
SET room_number = 1
WHERE room_number = 0;

-- Format number of rooms column as number
ALTER TABLE real_estate_arg.all_properties
MODIFY COLUMN room_number INT;

-- Save checkpoint with 'room_number' column cleaned
COMMIT;

#--------------------------------------------------3.7---------------------------------------------------------------------------

-- Check values for number of bathrooms, originally formatted as text, ordering in descending order to validate it does not contain non-numeric values
SELECT bathroom_number
FROM real_estate_arg.all_properties
GROUP BY bathroom_number
ORDER BY bathroom_number DESC;

-- Check for number of null values
SELECT bathroom_number, COUNT(bathroom_number)
FROM real_estate_arg.all_properties
WHERE bathroom_number = 0 OR bathroom_number = '';

-- Check for number of null values by type of property
SELECT property_type, bathroom_number, COUNT(bathroom_number)
FROM real_estate_arg.all_properties
WHERE bathroom_number = 0 OR bathroom_number = ''
GROUP BY property_type
ORDER BY COUNT(bathroom_number) DESC;

-- Check if properties with no number of bathrooms, have a covered area
SELECT property_type, COUNT(covered_area_m2), COUNT(bathroom_number)
FROM real_estate_arg.all_properties
WHERE bathroom_number = 0 OR bathroom_number = ''
GROUP BY property_type
ORDER BY COUNT(bathroom_number) DESC;

/*
Properties destined to personal and not commercial use, have at least 1 bathroom.
Assumption: default to '1' all properties destined for living.
Assumption: default to '0' all properties destined for commercial use.
*/
UPDATE real_estate_arg.all_properties
SET bathroom_number =
	CASE property_type
		WHEN 'Casa' THEN 1
        WHEN 'Departamento' THEN 1
        WHEN 'PH' THEN 1
        WHEN 'Edificio' THEN 1
        WHEN 'Hotel' THEN 1
        ELSE 0
        END
WHERE bathroom_number = 0 OR bathroom_number = '';

-- Format number of bathrooms column as number
ALTER TABLE real_estate_arg.all_properties
MODIFY COLUMN bathroom_number INT;

-- Save checkpoint with 'bathroom_number' column cleaned
COMMIT;

#--------------------------------------------------3.8---------------------------------------------------------------------------

-- Check values for expenses, originally formatted as text, ordering in descending order to validate it does not contain non-numeric values
SELECT expenses, COUNT(expenses)
FROM real_estate_arg.all_properties
GROUP BY expenses
ORDER BY expenses DESC;

-- Check blank expenses values by property
SELECT property_type, COUNT(expenses)
FROM real_estate_arg.all_properties
WHERE expenses = 'N/A'
GROUP BY property_type
ORDER BY property_type ASC;

-- Check number of currency types
SELECT expenses_currency, COUNT(expenses_currency)
FROM real_estate_arg.all_properties
GROUP BY expenses_currency
ORDER BY COUNT(expenses_currency) DESC;

-- Check expenses associated to expense currency 'N/A' and their number
SELECT expenses, expenses_currency, COUNT(expenses_currency)
FROM real_estate_arg.all_properties
WHERE expenses_currency = 'N/A'
GROUP BY expenses
ORDER BY COUNT(expenses_currency) DESC;

/*
All properties can be subject to expenses but not necessarily will. 
Assumption: Properties with expenses and expense currency both equal to 'N/A' have no expenses associated to them.
Considering the above assumption and that default currency in Argentina is ARS (Argentinean Pesos), all 'N/A' values in both columns will be replaced by '0' and 'ARS' respectively.
*/
UPDATE real_estate_arg.all_properties
SET expenses = 0, expenses_currency = 'ARS'
WHERE expenses = 'N/A' AND expenses_currency = 'N/A';

-- Check updated information
SELECT expenses, expenses_currency, COUNT(expenses_currency)
FROM real_estate_arg.all_properties
WHERE expenses = 0 AND expenses_currency = 'ARS'
GROUP BY expenses;

-- Check populated expenses associated to a blank expense currency and their number
SELECT expenses, expenses_currency, COUNT(expenses_currency)
FROM real_estate_arg.all_properties
WHERE expenses_currency = ''
GROUP BY expenses
ORDER BY COUNT(expenses_currency) DESC;

-- Count total records of blank expense currency
SELECT expenses_currency, COUNT(expenses)
FROM real_estate_arg.all_properties
WHERE expenses_currency = ''
GROUP BY expenses_currency;

-- Check total number of records with expenses of value 1 and their respective expency currency
SELECT COUNT(expenses), expenses_currency
FROM real_estate_arg.all_properties
WHERE expenses = 1
GROUP BY expenses_currency;

/*
There is not an unique expense currency, therefore replace expenses values for records with no expense currency with value '1'.
'1' value represents the property has associated expenses but its value is unidentified.
Assign 'ARS' as expense currency to these records, since 97% of current records with an expense value of 1 are expressed in ARS -and it is also the official currency in the country-.
*/
UPDATE real_estate_arg.all_properties
SET expenses = 1, expenses_currency = 'ARS'
WHERE expenses_currency = '';

-- Format number of bathrooms column as number
ALTER TABLE real_estate_arg.all_properties
MODIFY COLUMN expenses INT;

-- Save checkpoint with 'expenses' and 'expenses_currency' columns cleaned
COMMIT;

#--------------------------------------------------------------------------------------------------------------------------------