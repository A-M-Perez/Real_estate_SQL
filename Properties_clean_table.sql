#---------------------------------------------------1----------------------------------------------------------------------------
# Create new Database
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

# Visually check the data in the new table
SELECT *
FROM real_estate_arg.all_properties;

# Verify all records have been imported (should return 42.940)
SELECT COUNT(property_type)
FROM real_estate_arg.all_properties;

/* 
After confirmation all data is imported in one table, drop unnecessary (duplicate) tables.
Step can be skipped if properly imported in one table, or extended if more than 2 tables were required for import.
*/
DROP TABLE real_estate_arg.properties;
DROP TABLE real_estate_arg.properties2;

# Save checkpoint with imported data
COMMIT;

#---------------------------------------------------3----------------------------------------------------------------------------

# Check data types of each column
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

# Correct text format issue for properties with the name "Galp—n"
UPDATE real_estate_arg.all_properties
SET property_type = REPLACE(property_type, "Galp—n", "Galpon");

# Check for NULL values in property_type
SELECT property_type, COUNT(property_type) AS number_of_properties
FROM real_estate_arg.all_properties
WHERE property_type = ''
GROUP BY property_type
ORDER BY number_of_properties DESC;

# Save checkpoint after confirming "property_type" has valid values
COMMIT;

#--------------------------------------------------3.2---------------------------------------------------------------------------

/* 
Check locations available and the number of records per each of them, ordering the data with the highest number of properties per location in market at the top.
*/
SELECT location, COUNT(location) AS number_of_locations
FROM real_estate_arg.all_properties
GROUP BY location
ORDER BY number_of_locations DESC;

# Check the number of different locations
SELECT COUNT(DISTINCT(location))
FROM real_estate_arg.all_properties;

# Check for NULL values in location
SELECT location, COUNT(location) AS number_of_locations
FROM real_estate_arg.all_properties
WHERE location = ''
GROUP BY location
ORDER BY number_of_locations DESC;

# Delete from table, all null values in location
DELETE FROM real_estate_arg.all_properties
WHERE location = '';

# Add the 'province' column to be populated from the 'location' data
ALTER TABLE real_estate_arg.all_properties
ADD COLUMN province VARCHAR(255);

	# Extract the province for each of locations
	UPDATE real_estate_arg.all_properties
	SET province = TRIM(SUBSTRING_INDEX(location,',',-1));

	SELECT DISTINCT(province)
	FROM real_estate_arg.all_properties;

# Since too many locations have a text and number that is invalid, delete the specific string from the province name
UPDATE real_estate_arg.all_properties
SET province = REGEXP_REPLACE(province, 'solicitar precio [0-9]+', '');



--------------------------------------------------------------------------------------------------------------------------------
