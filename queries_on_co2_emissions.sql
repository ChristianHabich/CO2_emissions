-- Queries on public dataset CO2 emissions per country and year from ourworldindata.org
-- Original file split into four tables: countrydata, co2general, percapita, shareglobal

-- top and bottom five countries with respect to CO2 growth in mio tons over the last 20 years
(SELECT country,SUM(co2_growth_abs)::INT AS abs_change_co2_20y
FROM co2general
WHERE year between 1999 AND 2019 AND co2_growth_abs IS NOT NULL
GROUP BY country
ORDER BY abs_change_co2_20y ASC
LIMIT 5)
UNION
(SELECT country,SUM(co2_growth_abs)::INT AS abs_change_co2_20y
FROM co2general
WHERE year between 1999 AND 2019 AND co2_growth_abs IS NOT NULL
GROUP BY country
ORDER BY abs_change_co2_20y DESC
LIMIT 5)
ORDER BY abs_change_co2_20y DESC

-- CO2 growth average per decade for countries with more than 500 mio tons of CO2 emissions
SELECT
country,
	CASE
		WHEN (year BETWEEN 1970 AND 1979) THEN '70ties'
		WHEN (year BETWEEN 1980 AND 1989) THEN '80ties'
		WHEN (year BETWEEN 1990 AND 1999) THEN '90ties'
		WHEN (year BETWEEN 2000 AND 2009) THEN '2000+'
		WHEN (year BETWEEN 2010 AND 2019) THEN '2010+'
		ELSE 'before'
	END AS decades,
ROUND(AVG(co2_growth_prct),2) AS avg_co2_growth,
SUM(co2)::INT AS sum_co2
FROM co2general
WHERE year between 1970 AND 2019
GROUP BY country,decades
HAVING SUM(co2)>500
ORDER BY country,avg_co2_growth

-- CO2 (consumption) per capita of fossile energy exporting countries in 2018
SELECT percapita.country,percapita.co2_per_capita,percapita.consumption_co2_per_capita,subquery.share_global_flaring_co2,subquery.trade_co2_share
FROM (SELECT shareglobal.country,shareglobal.year,shareglobal.share_global_flaring_co2,shareglobal.trade_co2_share
	FROM shareglobal
	WHERE year = 2018 AND share_global_flaring_co2>0 AND trade_co2_share<0) AS subquery
	INNER JOIN percapita ON subquery.country = percapita.country AND subquery.year = percapita.year
ORDER BY percapita.co2_per_capita DESC

-- five year moving average of primary energy consumption per GDP for BRICS countries
SELECT iso_code,year,co2_per_gdp,energy_per_gdp,
ROUND(AVG(energy_per_gdp) OVER(PARTITION BY iso_code ROWS BETWEEN 5 PRECEDING AND CURRENT ROW),2) AS five_year_moving_avg_energy_per_gdp
FROM countrydata
WHERE year > 1990 AND energy_per_gdp IS NOT NULL AND country IN ('Brazil','Russia','India','China','South Africa')
ORDER BY iso_code,year

-- yearly rank of CO2 growth percentage between BRICS countries in 2016 to 2019
SELECT country,year,co2_growth_prct, 
RANK() OVER(PARTITION BY year ORDER BY co2_growth_prct)
FROM co2general
WHERE year BETWEEN 2016 AND 2019 AND country IN ('Brazil','Russia','India','China','South Africa')
ORDER BY country

-- average CO2 emission from different sources for countries with more than 700 mio tons of greenhouse gas emissions in 2015
SELECT country,
ROUND(AVG(cement_co2_per_capita),4) AS cement,
ROUND(AVG(coal_co2_per_capita),4) AS coal,
ROUND(AVG(flaring_co2_per_capita),4) AS flaring,
ROUND(AVG(gas_co2_per_capita),4) AS gas,
ROUND(AVG(oil_co2_per_capita),4) AS oil,
ROUND(AVG(other_co2_per_capita),4) AS other,
ROUND(AVG(ghg_per_capita),2) AS total_per_capita_t_co2
FROM percapita
WHERE year>2015 AND iso_code IN
	(SELECT
	iso_code
	FROM countrydata
	WHERE total_ghg>700)
GROUP BY country
ORDER BY total_per_capita_t_co2 DESC

-- average energy consumption per capita and per GDP (kilowatt-hour per dollar) for G7 and BRICS countries in the last 25 years
SELECT
	CASE
		WHEN (co2general.country IN ('France','Germany','Italy','Japan','United Kingdom','United States','Canada')) THEN 'G7'
		ELSE 'BRICS'
	END AS country_group,
co2general.year,
ROUND(AVG(co2general.co2_per_unit_energy),2) AS co2_per_unit_energy,
ROUND(AVG(countrydata.energy_per_gdp),2) AS energy_per_gdp,
AVG(percapita.energy_per_capita)::INT AS energy_per_capita
FROM co2general
RIGHT JOIN countrydata ON countrydata.country=co2general.country AND countrydata.year=co2general.year
RIGHT JOIN percapita ON percapita.country=co2general.country AND percapita.year=co2general.year
WHERE co2general.year > 1994 AND co2general.country IN ('France','Germany','Italy','Japan','United Kingdom','United States','Canada','Brazil','Russia','India','China','South Africa')
GROUP BY country_group,co2general.year

-- ordered share of global CO2 emission cumulated over 150 years for countries with a share of > 1% in 2015, allowing a comparison between historical with todays emission shares
SELECT percapita.country,share_global_cumulative_co2,share_global_co2,co2_per_capita,(gdp/population)::INT AS gdp_per_capita
FROM (SELECT country,year,share_global_cumulative_co2,share_global_co2 FROM shareglobal
	WHERE year=2015 and share_global_cumulative_co2>1) AS subquery
	INNER JOIN percapita ON percapita.country=subquery.country AND percapita.year=subquery.year
	INNER JOIN countrydata ON countrydata.country=subquery.country AND countrydata.year=subquery.year
ORDER BY share_global_cumulative_co2 DESC

-- emissions from oil vs. general emissions per capita for exemplary 'big and small islands' in 2016
SELECT percapita.country,co2_per_capita,oil_co2_per_capita,total_ghg,
	CASE
		WHEN population > 100000 THEN 'big island'
		ELSE 'small island'
	END AS island_size
FROM percapita
RIGHT JOIN countrydata ON countrydata.country=percapita.country AND countrydata.year=percapita.year
WHERE percapita.year=2016 AND co2_per_capita IS NOT NULL AND percapita.country ILIKE '%island%'
ORDER BY oil_co2_per_capita DESC

-- self join and csv export on percapita table, displaying countries with equal shares of CO2 per capita
COPY (SELECT pc1.country,pc2.country,pc1.co2_per_capita
FROM percapita AS pc1
INNER JOIN percapita AS pc2
ON pc1.country<>pc2.country AND pc1.co2_per_capita=pc2.co2_per_capita
WHERE pc1.year = 2005 AND pc1.co2_per_capita>1) TO 'C:\temp\myq.csv' DELIMITER ',' CSV HEADER;