USE My_project;

-- Firstly, let's have a quick look at the tables we have

SELECT 
  * 
FROM 
  Country;
SELECT 
  * 
FROM 
  Cases;
SELECT 
  * 
FROM 
  Vaccination;

-- Let's focus on data that is related to Ukraine

SELECT 
  * 
FROM 
  Country 
WHERE 
  location = 'Ukraine';
SELECT 
  * 
FROM 
  Cases 
WHERE 
  location = 'Ukraine';
SELECT 
  * 
FROM 
  Vaccination 
WHERE 
  location = 'Ukraine';

-- Looks like there are enough records to perform some analysis

-- Let's look at the percent of death in comparison to total cases and in comparison to the whole country population
-- Let's also calculate what percentage of the population got Covid19 
SELECT 
  location, 
  date, 
  total_cases, 
  total_deaths, 
  (total_deaths / total_cases)* 100 AS deaths_to_cases_percent, 
  (total_deaths / population)* 100 AS deaths_to_pop_percent, 
  (total_cases / population)* 100 AS cases_to_pop_percent 
FROM 
  Cases 
WHERE 
  location = 'Ukraine';

-- Let's now look at the percent of fully vaccinated people among the whole country population by date

SELECT 
  location, 
  date, 
  population, 
  new_vaccinations, 
  people_vaccinated, 
  people_fully_vaccinated, 
  (people_vaccinated / population)* 100 AS Percent_Vaccinated, 
  (people_fully_vaccinated / population)*100 AS Percent_Fully_Vaccinated 
FROM 
  Vaccination 
WHERE 
  location = 'Ukraine';

-- Let's join this two tables

SELECT 
  Cases.location, 
  Cases.date, 
  Cases.total_cases, 
  Cases.total_deaths, 
  (Cases.total_deaths / Cases.total_cases)*100 AS deaths_to_cases_percent, 
  (Cases.total_deaths / Cases.population)*100 AS deaths_to_pop_percent, 
  (Cases.total_cases / Cases.population)* 100 AS cases_to_pop_percent, 
  vac.new_vaccinations, 
  vac.people_vaccinated, 
  vac.people_fully_vaccinated, 
  (vac.people_vaccinated / vac.population)*100 as Percent_Vaccinated, 
  (vac.people_fully_vaccinated / vac.population)*100 as Percent_Fully_Vaccinated 
FROM 
  Cases 
INNER JOIN 
  Vaccination vac 
ON 
  Cases.date = vac.date 
AND 
  Cases.location = vac.location 
WHERE 
  Cases.location = 'Ukraine';

-- It may be interesting to visualize this data later, so let's create a view. We'll replace all the NULLs with 0

DROP VIEW IF EXISTS CasesVsVaccinUkraine;

CREATE VIEW CasesVsVaccinUkraine AS (
  SELECT 
    Cases.location, 
    Cases.date, 
    COALESCE(Cases.total_cases, 0) as total_cases, 
    COALESCE(Cases.total_deaths, 0) as total_deaths,
	COALESCE(Cases.new_cases, 0) as new_cases, 
    COALESCE(Cases.new_deaths, 0) as new_deaths,
    COALESCE((Cases.total_deaths / Cases.total_cases)*100, 0) as Death_Percentage, 
    COALESCE((Cases.total_deaths / Cases.population)*100, 0) as Deaths_To_Cases, 
    COALESCE((Cases.total_cases / Cases.population)*100, 0) as Percent_of_people_got_covid, 
    vac.new_vaccinations,
	vac.total_vaccinations,
    vac.people_vaccinated, 
    vac.people_fully_vaccinated, 
    (vac.people_vaccinated / vac.population)*100 as Percent_vaccinated, 
    (vac.people_fully_vaccinated / vac.population)*100 as Percent_fully_vaccinated
  FROM 
    Cases 
  INNER JOIN 
	Vaccination vac 
  ON 
	Cases.date = vac.date 
  AND 
	Cases.location = vac.location 
  WHERE 
    Cases.location = 'Ukraine'
);

SELECT
  *
FROM
  CasesVsVaccinUkraine;

-- Let's also create a view with the same data to compare Ukraine with other european countries

DROP VIEW IF EXISTS CasesVsVaccinEurope;

CREATE VIEW CasesVsVaccinEurope AS (
  SELECT 
    Cases.location, 
    Cases.date, 
	Cases.population,
    COALESCE(Cases.total_cases, 0) as total_cases, 
    COALESCE(Cases.total_deaths, 0) as total_deaths,
	COALESCE(Cases.new_cases, 0) as new_cases, 
    COALESCE(Cases.new_deaths, 0) as new_deaths,
    COALESCE((Cases.total_deaths / Cases.total_cases)*100, 0) as Death_Percentage, 
    COALESCE((Cases.total_deaths / Cases.population)*100, 0) as Deaths_To_Cases, 
    COALESCE((Cases.total_cases / Cases.population)*100, 0) as Percent_of_people_got_covid, 
    vac.new_vaccinations,
	vac.total_vaccinations,
    vac.people_vaccinated, 
    vac.people_fully_vaccinated, 
    (vac.people_vaccinated / vac.population)*100 as Percent_vaccinated, 
    (vac.people_fully_vaccinated / vac.population)*100 as Percent_fully_vaccinated
  FROM 
    Cases 
  INNER JOIN 
	Vaccination vac 
  ON 
	Cases.date = vac.date 
  AND 
	Cases.location = vac.location 
  WHERE 
    Cases.continent = 'Europe'
);

SELECT
	*
FROM
	CasesVsVaccinEurope
WHERE
 location = 'Gibraltar'
-- Let's now look at the data according to the continents. It's important to note that if we want to do it, we should add
-- the condition "continent IS NULL" because of the structure of the data

SELECT 
  * 
FROM 
  Cases 
WHERE 
  continent IS NULL;

-- Let's see what continents are it the data by selecting distinct locations where continent is null

SELECT 
  DISTINCT location 
FROM 
  Cases 
WHERE 
  continent IS NULL;

-- As we can see, apart from the continents, there are also groupings by income level, so if we want to perform some operations 
-- like SUM or sth else breaking things down by continent, it's better to use the condition "continent IS NOT NULL" and
-- then group the results by continent

-- Let's now look at the total cases and total deaths by continent. For this we can simply add all the new cases and group that by location
-- We also should change the type of some columns to BIGINT to have an ability to apply SUM function to this column

SELECT 
  continent, 
  SUM(CAST(new_cases AS BIGINT)) as total_cases, 
  SUM(CAST(new_deaths AS BIGINT)) as total_deaths 
FROM 
  Cases 
WHERE 
  continent IS NOT NULL 
GROUP BY 
  continent 
ORDER BY 
  total_cases 
  
-- Let's add percentage measurements to this data just how we have done this earlier (but without breaking things down by date). 
-- To do this, we will use CTE

WITH Continents AS (
    SELECT 
      continent, 
      SUM(CAST(new_cases AS DECIMAL(11, 0))) as total_cases_by_continent, 
      SUM(CAST(new_deaths AS DECIMAL(11, 0))) as total_deaths_by_continent 
    FROM 
      Cases 
    WHERE 
      continent IS NOT NULL 
    GROUP BY 
      continent
  ) 
SELECT 
  continent, 
  total_cases_by_continent, 
  total_deaths_by_continent, 
  (total_deaths_by_continent / total_cases_by_continent)*100 AS Deaths_To_Cases_Percentage 
FROM 
  Continents 
ORDER BY 
  Deaths_To_Cases_Percentage 

-- Let's also look at the ration of total deaths and total cases to overall continent population
-- Let's use subqueries approach here. Here is the innermost query: selecting all the countries with their population

SELECT 
  continent, 
  location, 
  population 
FROM 
  Cases 
WHERE 
  continent IS NOT NULL 
GROUP BY 
  continent, 
  location, 
  population 
  
-- Let's now sum the population by continent

SELECT 
  continent, 
  SUM(population) AS Population 
FROM 
  (
    SELECT 
      continent, 
      location, 
      population 
    FROM 
      Cases 
    WHERE 
      continent IS NOT NULL 
    GROUP BY 
      continent, 
      location, 
      population
  ) population_by_countries_and_continents 
GROUP BY 
  continent 

-- Finally, let's join these table with the table we created earlier

SELECT 
  Cases.continent, 
  SUM(CAST(Cases.new_cases as NUMERIC)) as total_cases_by_continent, 
  SUM(CAST(Cases.new_deaths as NUMERIC)) as total_deaths_by_continent, 
  population_by_continent.Population 
FROM 
  Cases 
INNER JOIN (
    SELECT 
      continent, 
      SUM(population) as Population 
    FROM 
      (
        SELECT 
          continent, 
          location, 
          population 
        FROM 
          Cases 
        WHERE 
          continent IS NOT NULL 
        GROUP BY 
          continent, 
          location, 
          population
      ) population_by_countries_and_continents 
    GROUP BY 
      population_by_countries_and_continents.continent
  ) population_by_continent 
ON 
  population_by_continent.continent = Cases.continent 
GROUP BY 
  Cases.continent, 
  population_by_continent.Population; 

-- Now let's use CTE to count the ratio of deaths to population, cases to population, cases to deaths in percents

WITH continents_deaths_cases_pop as (
    SELECT 
      Cases.continent, 
      SUM(CAST(Cases.new_cases as NUMERIC)) as total_cases_by_continent, 
      SUM(CAST(Cases.new_deaths as NUMERIC)) as total_deaths_by_continent, 
      population_by_continent.Population 
    FROM 
      Cases 
    INNER JOIN (
        SELECT 
          continent, 
          SUM(population) AS Population 
        FROM 
          (
            SELECT 
              continent, 
              location, 
              population 
            FROM 
              Cases 
            WHERE 
              continent IS NOT NULL 
            GROUP BY 
              continent, 
              location, 
              population
          ) population_by_countries_and_continents 
        GROUP BY 
          population_by_countries_and_continents.continent
      ) population_by_continent 
	ON 
	  population_by_continent.continent = Cases.continent 
    GROUP BY 
      Cases.continent, 
      population_by_continent.Population
  ) 
SELECT 
  continent, 
  Population, 
  total_cases_by_continent, 
  total_deaths_by_continent, 
  (total_deaths_by_continent / total_cases_by_continent)*100 AS Deaths_To_Cases_Percent, 
  (total_deaths_by_continent / Population)*100 AS Deaths_To_Pop_Percent, 
  (total_cases_by_continent / Population)*100 AS Cases_To_Pop_Percent 
FROM 
  continents_deaths_cases_pop 
ORDER BY 
  Cases_To_Pop_Percent; 
  
-- Let's now create a temporary table with the data on cases, deaths, population

DROP TABLE IF EXISTS #Data_By_Continents;
CREATE TABLE #Data_By_continents(
  continent VARCHAR(20), 
  total_cases_by_continent BIGINT, 
  total_deaths_by_continent BIGINT, 
  Population DECIMAL(15, 0), 
  Deaths_To_Cases_Percent DECIMAL(15, 4), 
  Cases_To_Pop_Percent DECIMAL(15, 4), 
  Deaths_To_Pop_Percent DECIMAL(15, 4)
);

-- Let's insert into this table all the data we extracted in the previos query

WITH continents_deaths_cases_pop as (
  SELECT 
    Cases.continent, 
    SUM(CAST(Cases.new_cases as DECIMAL(15, 2))) as total_cases_by_continent, 
    SUM(CAST(Cases.new_deaths as DECIMAL(15, 2))) as total_deaths_by_continent, 
    population_by_continent.Population as Population 
  FROM 
    Cases 
  INNER JOIN (
      SELECT 
        continent, 
        SUM(population) AS Population 
      FROM 
        (
          SELECT 
            continent, 
            location, 
            population 
          FROM 
            Cases 
          WHERE 
            continent IS NOT NULL 
          GROUP BY 
            continent, 
            location, 
            population
        ) population_by_countries_and_continents 
      GROUP BY 
        population_by_countries_and_continents.continent
    ) population_by_continent 
	ON 
	  population_by_continent.continent = Cases.continent 
  GROUP BY 
    Cases.continent, 
    population_by_continent.Population
) 
INSERT INTO #Data_By_continents
SELECT 
  *, 
  (total_deaths_by_continent / total_cases_by_continent)*100, 
  (total_cases_by_continent / Population)*100, 
  (total_deaths_by_continent / Population)*100 
FROM 
  continents_deaths_cases_pop;

-- Let's check if everything is inserted properly

SELECT 
  * 
FROM 
  #Data_By_continents;

-- Let's count the average population density, gdp per capita, extreme poverty and human development index at every continent
-- and join this data to the data_by_continents table

SELECT 
  continent, 
  AVG(population_density) as Avg_pop_dens, 
  AVG(gdp_per_capita) as Avg_gdp, 
  AVG(human_development_index) as Avg_hum_dev_ind 
FROM 
  Country 
WHERE 
  continent IS NOT NULL 
GROUP BY 
  continent;

-- Here we join the data as promised, we'll refer to this table later

SELECT 
  #Data_By_continents.*,
  density_gdp_hum_dev_by_cont.Avg_gdp, 
  density_gdp_hum_dev_by_cont.Avg_hum_dev_ind, 
  density_gdp_hum_dev_by_cont.Avg_pop_dens 
FROM 
  #Data_By_continents
INNER JOIN (
    SELECT 
      continent, 
      AVG(population_density) AS Avg_pop_dens, 
      AVG(gdp_per_capita) AS Avg_gdp, 
      AVG(human_development_index) AS Avg_hum_dev_ind 
    FROM 
      Country 
    WHERE 
      continent IS NOT NULL 
    GROUP BY 
      continent
  ) density_gdp_hum_dev_by_cont 
ON 
  density_gdp_hum_dev_by_cont.continent = #Data_By_continents.continent;

-- Let's also count the number of people vaccinated in every continent

SELECT 
  continent, 
  location, 
  COALESCE(MAX(people_vaccinated), 0) as People_vaccinated -- MAX because the number of people vaccinated by the time the data was downloaded is the maximum number in people_vaccinated column in particular country
FROM 
  Vaccination 
WHERE 
  continent IS NOT NULL 
GROUP BY 
  continent, 
  location; 

-- Let's break than down by continent

SELECT 
  continent, 
  SUM(People_vaccinated) as People_vaccinated 
FROM 
  (
    SELECT 
      continent, 
      location, 
      COALESCE(MAX(people_vaccinated), 0) as People_vaccinated 
    FROM 
      Vaccination 
    WHERE 
      continent IS NOT NULL 
    GROUP BY 
      continent, 
      location
  ) continent_and_location_vaccinated 
GROUP BY 
  continent; 

-- Let's now join this table to the table we promised to refer to

SELECT 
  cases_deaths_gdp_hum_dev_pop_dens_by_continent.*, 
  vac_by_cont.People_vaccinated 
FROM 
  (
    SELECT 
      #Data_By_continents.*,
      density_gdp_hum_dev_by_cont.Avg_gdp, 
      density_gdp_hum_dev_by_cont.Avg_hum_dev_ind, 
      density_gdp_hum_dev_by_cont.Avg_pop_dens 
    FROM 
      #Data_By_continents
    INNER JOIN (
        SELECT 
          continent, 
          AVG(population_density) AS Avg_pop_dens, 
          AVG(gdp_per_capita) AS Avg_gdp, 
          AVG(human_development_index) AS Avg_hum_dev_ind 
        FROM 
          Country 
        WHERE 
          continent IS NOT NULL 
        GROUP BY 
          continent
      ) density_gdp_hum_dev_by_cont 
	  ON 
	    density_gdp_hum_dev_by_cont.continent = #Data_By_continents.continent
      ) cases_deaths_gdp_hum_dev_pop_dens_by_continent 
INNER JOIN (
    SELECT 
      continent, 
      SUM(People_vaccinated) AS People_vaccinated 
    FROM 
      (
        SELECT 
          continent, 
          location, 
          COALESCE(MAX(people_vaccinated), 0) as People_vaccinated 
        FROM 
          Vaccination 
        WHERE 
          continent IS NOT NULL 
        GROUP BY 
          continent, 
          location
      ) continent_and_location_vaccinated 
    GROUP BY 
      continent
  ) vac_by_cont
ON 
  vac_by_cont.continent = cases_deaths_gdp_hum_dev_pop_dens_by_continent.continent;
  
  -- Let's create a new (now permanent) table to store this data

DROP TABLE IF EXISTS data_by_continent;
CREATE TABLE data_by_continent(
    continent VARCHAR(20), 
    total_cases DECIMAL(11, 0), 
    total_deaths DECIMAL(11, 0), 
    population BIGINT, 
    deaths_to_cases_percent DECIMAL(6, 3), 
    cases_to_pop_percent DECIMAL(6, 3), 
    deaths_to_pop_percent DECIMAL(6, 3), 
    avg_gdp DECIMAL(12, 3), 
    avg_hum_dev_ind DECIMAL(10, 3), 
    avg_pop_dens DECIMAL(10, 3), 
    people_vaccinated DECIMAL(13, 0)
  );

INSERT INTO data_by_continent 
SELECT 
  cases_deaths_gdp_hum_dev_pop_dens_by_continent.*, 
  COALESCE(vac_by_cont.People_vaccinated, 0) 
FROM 
  (
    SELECT 
      #Data_By_continents.*,
      density_gdp_hum_dev_by_cont.Avg_gdp, 
      density_gdp_hum_dev_by_cont.Avg_hum_dev_ind, 
      density_gdp_hum_dev_by_cont.Avg_pop_dens 
    FROM 
      #Data_By_continents
    INNER JOIN (
        SELECT 
          continent, 
          AVG(population_density) AS Avg_pop_dens, 
          AVG(gdp_per_capita) AS Avg_gdp, 
          AVG(human_development_index) AS Avg_hum_dev_ind 
        FROM 
          Country 
        WHERE 
          continent IS NOT NULL 
        GROUP BY 
          continent
      ) density_gdp_hum_dev_by_cont 
	  ON 
		density_gdp_hum_dev_by_cont.continent = #Data_By_continents.continent
      ) cases_deaths_gdp_hum_dev_pop_dens_by_continent 
INNER JOIN (
    SELECT 
      continent, 
      SUM(People_vaccinated) AS People_vaccinated 
    FROM 
      (
        SELECT 
          continent, 
          location, 
          COALESCE(MAX(people_vaccinated), 0) as People_vaccinated 
        FROM 
          Vaccination 
        WHERE 
          continent IS NOT NULL 
        GROUP BY 
          continent, 
          location
      ) continent_and_location_vaccinated 
    GROUP BY 
      continent
  ) vac_by_cont 
ON 
  vac_by_cont.continent = cases_deaths_gdp_hum_dev_pop_dens_by_continent.continent; 
  
-- Now let's add the column of the percent ratio of people vaccinated to the whole population

SELECT 
  *, 
  (people_vaccinated / population)*100 as percent_of_people_vaccinated 
FROM 
  data_by_continent;

-- Let's now create a view from this table for further visualizations

DROP VIEW IF EXISTS continent_data_view;
CREATE VIEW continent_data_view as (
  SELECT 
    *, 
    COALESCE((people_vaccinated / population)*100, 0) as percent_of_people_vaccinated 
  FROM 
    data_by_continent
);

-- Let's now drop the temporary table we created - we don't need it anymore

DROP TABLE #Data_By_continents;

-- It may also be interesting to compare the best country in every continent according to the human development index or GDP per capita
-- in terms of number of cases, vaccinations and deaths
-- Let's extract firstly the top countries in every continent according to the human development index
-- We can use window function rank() here to rank all the countries in every continent by human development index

WITH rank_hum_dev_index as (
    SELECT 
      continent, 
      location, 
      human_development_index, 
      RANK() OVER (
        PARTITION BY 
			continent 
        ORDER BY 
          human_development_index DESC
      ) AS rank_hd 
    FROM 
      Country 
    WHERE 
      Continent IS NOT NULL
  ) 
SELECT 
  continent, 
  location, 
  human_development_index 
FROM 
  rank_hum_dev_index 
WHERE 
  rank_hd = 1 
GROUP BY 
  continent, 
  location, 
  human_development_index;

-- Let's create a temporary table with this data

DROP TABLE IF EXISTS Human_development_top;
CREATE TABLE Human_development_top(
  continent VARCHAR(20), 
  location VARCHAR(20), 
  human_development_index DECIMAL(10, 3)
);

WITH rank_hum_dev_index AS (
  SELECT 
    continent, 
    location, 
    human_development_index, 
    RANK() OVER (
      PARTITION BY 
	    continent 
      ORDER BY 
        human_development_index DESC
    ) AS rank_hd 
  FROM 
    Country 
  WHERE 
    Continent IS NOT NULL
) 
INSERT INTO Human_development_top 
SELECT 
  continent, 
  location, 
  human_development_index 
FROM 
  rank_hum_dev_index 
WHERE 
  rank_hd = 1 
GROUP BY 
  continent, 
  location, 
  human_development_index;

-- Let's check if everything was inserted properly

SELECT 
  * 
FROM 
  Human_development_top;

-- Let's do the same with gdp per capita

DROP TABLE IF EXISTS gdp_top;
CREATE TABLE gdp_top(
  continent VARCHAR(20), 
  location VARCHAR(20), 
  gdp_per_capita DECIMAL(10, 3)
);

WITH ranked_gdp as (
  SELECT 
    continent, 
    location, 
    gdp_per_capita, 
    RANK() OVER (
      PARTITION BY
		continent 
      ORDER BY 
        gdp_per_capita DESC
    ) AS rank_gdp 
  FROM 
    Country 
  WHERE 
    Continent IS NOT NULL
) 
INSERT INTO gdp_top 
SELECT 
  continent, 
  location, 
  gdp_per_capita 
FROM 
  ranked_gdp 
WHERE 
  rank_gdp = 1 
GROUP BY 
  continent, 
  location, 
  gdp_per_capita;

SELECT 
  * 
FROM 
  gdp_top;

-- Now let's extract the  new cases, total cases, new deaths, total deaths, new vaccinations, total vaccinations for these countries
-- First for countries with the highest development index in the continent

SELECT 
  Cases.continent, 
  Cases.location, 
  Cases.date, 
  Cases.population, 
  Cases.new_cases, 
  Cases.total_cases, 
  Cases.new_deaths, 
  Cases.total_deaths, 
  vac.new_vaccinations, 
  vac.total_vaccinations 
FROM 
  Cases 
INNER JOIN 
  Vaccination vac 
ON 
  Cases.location = vac.location 
AND Cases.date = vac.date 
WHERE 
  Cases.location IN (
    SELECT 
      location 
    FROM 
      Human_development_top
  );

-- Now let's create a view using this table
DROP VIEW IF EXISTS Top_countries_human_development_index;
CREATE VIEW Top_countries_human_development_index as (
    SELECT 
      Cases.continent, 
      Cases.location, 
      Cases.date, 
      Cases.population, 
      COALESCE(Cases.new_cases, 0) as new_cases, 
      COALESCE(Cases.total_cases, 0) as total_cases, 
      COALESCE(Cases.new_deaths, 0) as new_deaths, 
      COALESCE(Cases.total_deaths, 0) as total_deaths, 
      COALESCE(vac.new_vaccinations, 0) as new_vaccinations, 
      COALESCE(vac.total_vaccinations, 0) as total_vaccinations 
    FROM 
      Cases 
    INNER JOIN 
	  Vaccination vac 
	ON 
	  Cases.location = vac.location 
    AND 
	  Cases.date = vac.date 
    WHERE 
      Cases.location IN (
        SELECT 
          location 
        FROM 
          Human_development_top
      )
  ); 

-- Finally, let's create a view for the top countries in every continent according to the gdp per capita

DROP VIEW IF EXISTS Top_countries_gdp;
CREATE VIEW Top_countries_gdp AS (
    SELECT 
      Cases.continent, 
      Cases.location, 
      Cases.date, 
      Cases.population, 
      COALESCE(Cases.new_cases, 0) as new_cases, 
      COALESCE(Cases.total_cases, 0) as total_cases, 
      COALESCE(Cases.new_deaths, 0) as new_deaths, 
      COALESCE(Cases.total_deaths, 0) as total_deaths, 
      COALESCE(vac.new_vaccinations, 0) as new_vaccinations,  
      COALESCE(vac.total_vaccinations, 0) as total_vaccinations
    FROM 
      Cases 
    INNER JOIN 
	  Vaccination vac 
	ON 
	  Cases.location = vac.location 
    AND 
	  Cases.date = vac.date 
    WHERE 
      Cases.location IN (
        SELECT 
          location 
        FROM 
          gdp_top
      )
  );


