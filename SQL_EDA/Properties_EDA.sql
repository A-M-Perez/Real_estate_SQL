-- Visually check types of properties and the number of them by total area in m2
SELECT property_type, total_area_m2, COUNT(property_type)
FROM real_estate_arg.all_properties
GROUP BY total_area_m2
ORDER BY total_area_m2 DESC;

-- Detect and address possible anomalies in the data, analyzing each property type separately.

-- Apartments
	/*
    Check provinces with biggest apartments, to understand if they have more space and therefore properties could be bigger due to it.
    Visually check reasonability of sizes between the biggest apartments in different provinces.
    */
	SELECT property_type, MAX(total_area_m2), province
	FROM real_estate_arg.all_properties
	WHERE property_type = 'Departamento'
    GROUP BY province
    ORDER BY MAX(total_area_m2) DESC;

	-- Buenos Aires comes 6th in the list, with its biggest apartment being 740m2. Considering this is a really big apartment but reasonable to exists, set it as 'benchmark' to further analyze the dataset
     
    -- Check for bigger apartments in the rest of the provinces.
	SELECT province, neighbourhood_or_city, total_area_m2, covered_area_m2, room_number, price, (price / total_area_m2) AS avg_m2_price
    FROM real_estate_arg.all_properties
    WHERE property_type = 'Departamento' AND total_area_m2 > 740
    ORDER BY province ASC, total_area_m2 DESC;