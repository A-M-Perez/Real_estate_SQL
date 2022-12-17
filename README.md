# REMAX Real Estate Data Cleaning & EDA

.

## Project objective

create dataset to Analyze pricing.

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
><br>
>- Import REMAX properties data to table 'all_properties' (2) *(42.940 records)*
><br>
>- Clean 'all_properties' table (3)<br><br>
>     Check format of all columns<br>
>     'property_type': fix typos/text format issues and remove blanks (3.1) *(no blanks)*<br>
>     'location': remove blanks *(260 records - 0.6%)*, add 'province' field extracted from the 'location' field and clean the data to leave only valid -and identifiable- provinces' names *(1851 records - 4.3%)*, add 'neighbourhood_or_city' field extracted from the 'location' field and clean the data to leave only valid -and identifiable- neighbourhood or city names *(no blanks)* (3.2) <br>
>     'price': remove non-numeric values *(1795 records - 4.2%)* and format column as number (3.3)<br> 
>     'price_currency': remove records not expressed in USD *(205 records - 0.5%)* (3.3)<br>
>     'total_area_m2': (3.4)<br>
>     'covered_area_m2': (3.5)<br>
>     'room_number': (3.6)<br>
>     'bathroom_number': (3.7)<br>
>     'expenses': (3.8)<br>
>     'expenses_currency': (3.8)<br>

## Main SQL Statements applied

**DDL applied**
- CREATE DATABASE IF NOT EXISTS
- USE

**DDM applied**
- SELECT
- 

## How this project helped me grow:

xx

## Final considerations

xx