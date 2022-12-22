# REMAX Real Estate -Basic- EDA & Data Cleaning

REMAX is one of the main Real Estate (Agent) companies in Argentina, with a significant portion of the market under scope and which manages most of its marketing through a website (https://www.remax.com.ar).

## Project objective

This project aims to clean a raw dataset with real estate data -downloaded from Remax's website- using SQL with MySQL.

*Data source*: https://www.remax.com.ar <br>
*Dataset*: Real_estate_ARG.csv
(downloaded with web scraper: https://github.com/A-M-Perez/Real_Estate_web_scraper)

## (Raw) Data description

- ***Property_Type:*** refers to the type of property defined by the website filters, such as "House", "Apartment", "Office", etc.

- ***Location:*** refers to the neighbourhood/City and Province in which the property is located.

- ***Price:*** price of the property.

- ***Price_Currency:*** currency in which the price of the property is expressed (USD or ARS).

- ***Total_Area_m2:*** total size of the property, expressed in square meters. Total area = covered area + uncovered area.

- ***Covered_Area_m2:*** size of the covered area of the property, which is included in its total size, also expressed in square meters.

- ***Room_number:*** number of bedrooms in the property.

- ***Bathroom_number:*** number of bathrooms and toilets in the property.

- ***Expenses:*** approximate amount of monthly expenses (services, security, etc.) of the property.

- ***Expenses_Currency:*** currency in which the amount of expenses is expressed.

## Repository overview / structure

├── Properties_clean_README.md\
├── Properties_clean_table.sql\
├── Data_source\
&emsp;&emsp;├── Real_estate_ARG.csv

## Steps taken in the process

*All steps detailed below have their corresponding reference to that in the commented SQL code*

>&nbsp;
>- Create Database (1)
><br>
>- Import REMAX properties data to table 'all_properties' (2) *(42.940 records)*
><br>
>- Clean 'all_properties' table (3)<br><br>
>     Check format of all columns<br>
>
>     'property_type' (3.1)
>> - Fix typos or text format issues
>> - Remove blanks *(no records removed)*
>
>     'location' (3.2)
>> - Remove blanks *(260 records removed - 0.6%)*
>> - Add 'province' field extracted from the 'location' field
>>    - Clean the data to leave only valid -and identifiable- provinces' names *(1851 records removed - 4.3%)*
>> - Add 'neighbourhood_or_city' field extracted from the 'location' field
>>    - Clean the data to leave only valid -and identifiable- neighbourhood or city names *(no records removed)*
>> - Remove 'location' column (no further use in the dataset)
>
>     'price' & 'price_currency' (3.3)
>> - Remove non-numeric or blank price values *(1795 records removed - 4.2%)*
>> - Remove records not expressed in USD *(205 records removed - 0.5%)*
>> - Format column as number
>
>     'total_area_m2' (3.4)
>> - Remove non-numeric or blank values *(no records removed)*
>> - Format column as number 
>
>     'covered_area_m2': (3.5)<br>
>> - Remove non-numeric, blank, or invalid values *(7 records removed - 0.01%)*
>> - Format column as number
>
>     'room_number' (3.6)
>> - Remove non-numeric, or invalid values *(no records removed)*
>> - Default blank values to '1', since all properties with covered area, have at least 1 room *(2069 records updated)*
>> - Format column as number
>
>     'bathroom_number' (3.7)
>> - Remove non-numeric, or invalid values *(no records removed)*
>> - Default blank values to '1' if property is destined for living and '0' for commercial use *(343 records updated)*
>> - Format column as number
>
>     'expenses' & 'expenses_currency' (3.8)
>> - Remove non-numeric, or invalid values *(no records removed)*
>> - Default 'N/A' values to 0 expenses in ARS for properties with no expenses *(22,923 records updated)*.
>> - Default blank expenses currency values to ARS and assign value of 1 to the corresponding expenses  *(208 records updated)*.
>> - Format column as number
>
>&nbsp;

## How this project helped me grow:

> *First lesson learned: NEVER do an UPDATE prior to checking its results with SELECT*

One of the main challenges was to work with real life data from a website, which had a lot of missing values and not thoroughly standardized data across postings. I applied basic Exploratory Data Analysis and cleaning techniques, basing some of it on domain knowledge but also researching market specificities.

Of course, this project also helped me apply and therefore grow my SQL knowledge, having to revert to training documents and internet forums to troubleshoot different errors/situations.

I also had the opportunity to commit and even revert files' updates using Git & Github, through different stages of the process.

## Final considerations

As stated, this project aims at doing basic EDA and cleaning of a raw dataset, settling the basis for a deeper EDA and further analysis of these data, which is strictly necessary prior to move to a Visualization stage.