# REMAX Real Estate Exploratory Data Analysis (EDA)

REMAX is one of the main Real Estate (Agent) companies in Argentina, with a significant portion of the market under scope and which manages most of its marketing through a website (https://www.remax.com.ar).

## Project objective

This project aims to perform Exploratory Data Analysis over real estate data using SQL with MySQL.

Through SQL statements, I intend to understand and clean -where necessary- this data, creating views and simple stored procedures at the end.

*Dataset*: REMAX_real_estate_ARG.csv
*Data source*: https://github.com/A-M-Perez/Real_estate_SQL/tree/main/SQL_Data_Cleaning

*Dataset*: population_and_km2_area (manual table in SQL code)
*Data source*:https://www.ign.gob.ar/NuestrasActividades/Geografia/DatosArgentina/DivisionPolitica

## Data dictionary

- ***Property_Type:*** This field contains the type of property defined in the website, such as "House", "Apartment", "Office", etc. Values cannot be NULL and the data type is TEXT.

- ***Price:*** This field contains the price of the property. Values should not be zero or negative and the data type is INTEGER.

- ***Price_Currency:*** This field contains the currency in which the price of the property is expressed. Only possible values are USD and ARS, and the data type is TEXT.

- ***Total_Area_m2:*** This field contains the total size of the property, expressed in square meters. Total area = covered area + uncovered area. Values cannot be zero or negative and data type is INTEGER.

- ***Covered_Area_m2:*** This field contains the size of the covered area of the property, which is included in its total size, also expressed in square meters. Properties destined for living cannot have zero values. Properties related to Land can have zero values. Such properties are: 'Chacra' and 'Quinta'. No value can be negative. Data type is INTEGER.

- ***Room_number:*** This field contains the number of bedrooms in the property. Properties with covered area must have at least 1 room. Values cannot be negative and data type is INTEGER.

- ***Bathroom_number:*** This field contains the number of bathrooms and toilets in the property. Properties destined for living cannot have zero values. Properties related to Land can have zero values. Such properties are: 'Chacra' and 'Quinta'. No value can be negative. Data type is INTEGER.

- ***Expenses:*** This field contains the approximate amount of monthly expenses (services, security, etc.) of the property. Expenses cannot be higher than the property price nor can be negative values. Data type is INTEGER.

- ***Expenses_Currency:*** This field contains the currency in which the amount of expenses is expressed. Only possible values are USD and ARS, and the data type is TEXT.

## Repository overview / structure

├── README.md\
├── Properties_EDA.sql\
├── Data_source\
&emsp;&emsp;├── REMAX_real_estate_ARG.csv

## Steps taken in the process

*All steps detailed below have their corresponding reference to that in the commented SQL code*

>&nbsp;
>- Understand market share of property types (1)
><br>
>> *'Departamento', 'Casa', and 'PH' add up to 93.77% of properties being sold. Following steps only focus on these 3 properties*
>&nbsp;
>- Understand pricing and size of properties (2)
>- Individually analyze and understand properties: 'Departamento' (3)
>- Individually analyze and understand properties: 'Casa' (4)
>- Individually analyze and understand properties: 'PH' (5)
>- Remove unused columns (6)
>- Work with an additional table (population and areas) to perform additional EDA (7)
>- Create Views (8)
>- Create Stored Procedures (9)
>&nbsp;

## How this project helped me grow:

> *First lesson learned: NEVER do an UPDATE or DELETE prior to checking its results with SELECT*

One of the main challenges, besides working with real life data, was to apply SQL statements to see the data in ways that would add value to the user, using aggregations and comparissons between the same and other tables.

It was also a great practice to continue exercising what questions might return most value from its analysis. 

I also had the opportunity to continue leveraging Git & Github's functionalities, through different stages of the process.

## Final considerations

As stated, this project aims at doing EDA and further cleaning of the dataset, however, I only focused on the most significative groups of data and cleaned it to the extent where the cost-benefit assessment was positive. The latest means that if someone is to use the final dataset obtained, please consider that further cleaning might be needed and by no means this is intended for immediate use in a Visualization stage.