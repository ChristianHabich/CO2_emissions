# CO2_emissions
Queries on public dataset CO2 emissions per country and year from ourworldindata.org.
Original file split into four tables: countrydata, co2general, percapita, shareglobal

- each table contains year, country name and iso code as base information
- countrydata holds data about total greenhouse gas emissions, energy consumption, gdp and population
- co2general holds data about relative/absolute co2 growth, cumulative co2 emissions and co2 emissions from different sources (oil, gas, cement, flaring etc.)
- percapita holds data about co2 emissions from different sources divided by a country's population in the respective year
- shareglobal holds data about the share of (cumulative) emissions per country from different sources in relation to global emissions

Original data set: https://github.com/owid/co2-data/blob/master/owid-co2-data.csv.
Code book for descriptions of all column headers: https://github.com/owid/co2-data/blob/master/owid-co2-codebook.csv.

More about Our World in Data (owid): https://ourworldindata.org/co2-and-other-greenhouse-gas-emissions

Sources of owid data set: Global Carbon Project, Climate Watch Portal, BP Statistical Review of World Energy, World Bank Development Indicators
