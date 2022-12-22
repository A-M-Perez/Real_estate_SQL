# REMAX Real Estate Exploratory Data Analysis

xx

## Project objective

xx

*Data source*: <br>
*Dataset*: 

## Data dictionary

- ***Property_Type:*** This field contains the type of property defined in the website, such as "House", "Apartment", "Office", etc. Values cannot be NULL and the data type is TEXT.

- ***Price:*** This field contains the price of the property. Values should not be zero or negative and the data type is INTEGER.

- ***Price_Currency:*** This field contains the currency in which the price of the property is expressed. Only possible values are USD and ARS, and the data type is TEXT.

- ***Total_Area_m2:*** This field contains the total size of the property, expressed in square meters. Total area = covered area + uncovered area. Values cannot be zero or negative and data type is INTEGER.

- ***Covered_Area_m2:*** This field contains the size of the covered area of the property, which is included in its total size, also expressed in square meters. Properties destined for living cannot have zero values. Properties related to Land can have zero values. Such properties are: Chacra and Quinta. No value can be negative. Data type is INTEGER.

- ***Room_number:*** This field contains the number of bedrooms in the property. Properties with covered area must have at least 1 room. Values cannot be negative and data type is INTEGER.

- ***Bathroom_number:*** This field contains the number of bathrooms and toilets in the property. Properties destined for living cannot have zero values. Properties related to Land can have zero values. Such properties are: Chacra and Quinta. No value can be negative. Data type is INTEGER.

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
>-  (1)
><br>
>-  (2) *(42.940 records)*
><br>
>-  (3)<br><br>
>     <br>
>
>     'xx' (3.1)
>> - xx
>> - xx *(no records removed)*
>
>    
>
>&nbsp;

## How this project helped me grow:

> *First lesson learned: NEVER do an UPDATE prior to checking its results with SELECT*

One of the main challenges was to work with real life data from a website, which had a lot of missing values and not thoroughly standardized data across postings. I applied basic Exploratory Data Analysis and cleaning techniques, basing some of it on domain knowledge but also researching market specificities.

Of course, this project also helped me apply and therefore grow my SQL knowledge, having to revert to training documents and internet forums to troubleshoot different errors/situations.

I also had the opportunity to commit and even revert files' updates using Git & Github, through different stages of the process.

## Final considerations

As stated, this project aims at doing basic EDA and cleaning of a raw dataset, settling the basis for a deeper EDA and further analysis of these data, which is strictly necessary prior to move to a Visualization stage.