# REMAX Real Estate Data Cleaning & EDA

.

## Project objective

.

Data source: https://www.remax.com.ar
Dataset: xxx
(downloaded with web scraper: https://github.com/A-M-Perez/Real_Estate_web_scraper)

## Data description

- ***Property_Type:*** refers to the type of property defined by the website filters, such as "House", "Apartment", "Office", etc.

- ***Location:*** refers to the neighbourhood and Province in which the property is located.

- ***Price:*** price of the property.

- ***Price_Currency:*** currency in which the price of the property is expressed (USD or ARS).

- ***Total_Area_m2:*** total size of the property, expressed in square meters. Total area = covered area + uncovered area.

- ***Covered_Area_m2:*** size of the covered area of the property, which is included in its total size, also expressed in square meters.

- ***Room_number:*** number of bedrooms in the property.

- ***Bathroom_number:*** number of bathrooms and toilets in the property.

- ***Expenses:*** approximate amount of monthly expenses (services, security, etc.) of the property.

- ***Expenses_Currency:*** currency in which the amount of expenses is expressed.

## Repository overview / structure

├── README.md\
├── .sql ()\
├── Data_source\
    ├── Real_estate_ARG.csv ()\
    ├── .csv ()

## Logical steps taken

*All steps detailed below have their corresponding reference to that in the commented code*

>- Create Database (1)
>- Import REMAX properties data to table 'all_properties' (2) *(42.940 records)*
>- Clean 'all_properties' table (3)<br><br>
>     Check format of all columns<br>
<<<<<<< HEAD
=======
<<<<<<< HEAD
>>>>>>> ec8e2fe94fef870da588d15159506bf459453c5f
>
>     'property_type' (3.1)
>      > - Fix typos or text format issues
>      > - Remove blanks *(no records removed)*
>
>     'location' (3.2)
>      > - Remove blanks *(260 records removed - 0.6%)*
>      > - Add 'province' field extracted from the 'location' field
>      >    - Clean the data to leave only valid -and identifiable- provinces' names *(1851 records removed - 4.3%)*
>      > - Add 'neighbourhood_or_city' field extracted from the 'location' field
>      >    - Clean the data to leave only valid -and identifiable- neighbourhood or city names *(no records removed)*
<<<<<<< HEAD
>      > - Remove 'location' column (no further use in the dataset)
=======
>>>>>>> ec8e2fe94fef870da588d15159506bf459453c5f
>
>     'price' (3.3)
>      > - Remove non-numeric or blank values *(1795 records removed - 4.2%)*
>      > - Format column as number
>
>     'price_currency' (3.3)
>      > - Remove records not expressed in USD *(205 records removed - 0.5%)*
>
>     'total_area_m2' (3.4)
>      > - Remove non-numeric or blank values *(no records removed)*
>      > - Format column as number 
>
>     'covered_area_m2': (3.5)<br>
>      > - Remove non-numeric, blank, or invalid values *(7 records removed - 0.01%)*
>      > - Format column as number
>
>     'room_number' (3.6)
>      > - Remove non-numeric, or invalid values *(no records removed)*
>      > - Default blank values to '1', since all properties with covered area, have at least 1 room *(2069 records updated)*
>      > - Format column as number
>
>     'bathroom_number' (3.7)
>      > - Remove non-numeric, or invalid values *(no records removed)*
<<<<<<< HEAD
>      > - Default blank values to '1' if property is destined for living and '0' for commercial use *(343 records updated)*
>      > - Format column as number
>
>     'expenses' & 'expenses_currency' (3.8)
>      > - Remove non-numeric, or invalid values *(no records removed)*
>      > - Default 'N/A' values to 0 expenses in ARS for properties with no expenses *(22,923 records updated)*.
>      > - Default blank expenses currency values to ARS and assign value of 1 to the corresponding expenses  *(208 records updated)*.
>      > - Format column as number
>
=======
>      > - Default blank values to '1' if property is destined for living and '0' for commercial use 
>      > - Format column as number
>
>     'expenses': (3.8)<br>
>     'expenses_currency': (3.8)<br>
=======
>     'property_type': fix typos/text format issues and remove blanks (3.1) *(no blanks)*<br>
>     'location': remove blanks *(260 records - 0.6%)*, add 'province' field extracted from the 'location' field and clean the data to leave only valid -and identifiable- provinces' names *(1851 records - 4.3%)*, add 'neighbourhood_or_city' field extracted from the 'location' field and clean the data to leave only valid -and identifiable- neighbourhood or city names *(no blanks)* (3.2) <br>
>     'price' - (3.3)<br> 
>     'price_currency' - (3.4)<br>
>     'total_area_m2' - (3.5)<br>
>>>>>>> parent of 41927aa (Cleaned Price and Price_Currency columns; Added steps to README.md)

## Main SQL Statements applied

**DDL applied**
- CREATE DATABASE IF NOT EXISTS
- USE

**DDM applied**
- SELECT
- 
>>>>>>> ec8e2fe94fef870da588d15159506bf459453c5f

## How this project helped me grow:

**First lesson learned: NEVER do an UPDATE prior to checking its results with SELECT**


## Final considerations

xx