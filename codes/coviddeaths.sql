/*
COVID-19 DEATHS AND VACCINATION: DATA EXPLORATION
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

	SELECT *
	FROM CovidProject.coviddeaths
	WHERE continent IS NOT NULL
	ORDER BY 3,4;

-- Select the data that we are going to be starting with
-- Notice that location includes other group such as World, International, Income class, etc. 
-- We're going to exclude those locations

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject.coviddeaths
WHERE continent <> ''
AND continent IS NOT NULL
AND location NOT IN ('world', 'Upper middle income', 'High income', 'Lower middle income', 'Low income', 'International', 'European Union', 'Asia')
ORDER BY 1,2;

-- TOTAL CASES VS TOTAL DEATHS
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM CovidProject.coviddeaths
WHERE location = 'philippines' 
AND continent <> ''
AND continent IS NOT NULL
AND location NOT IN ('world', 'Upper middle income', 'High income', 'Lower middle income', 'Low income', 'International', 'European Union', 'Asia')
ORDER BY 1,2;

-- TOTAL CASES VS POPULATION
-- Shows what percentage of population got covid

SELECT location, date, total_cases, population, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidProject.coviddeaths
WHERE location = 'philippines' 
AND continent <> ''
AND continent IS NOT NULL
AND location NOT IN ('world', 'Upper middle income', 'High income', 'Lower middle income', 'Low income', 'International', 'European Union', 'Asia')
ORDER BY 1,2;

-- Countries with Highest Infection Rate compared to Population
-- To be used in Tableau visualization

SELECT location, population, MAX(total_cases) AS HighestInfectCount,  MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidProject.coviddeaths
WHERE continent <> ''
AND continent IS NOT NULL
AND location NOT IN ('world', 'Upper middle income', 'High income', 'Lower middle income', 'Low income', 'International', 'European Union', 'Asia')
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Infection Rate compared to Population with DATE
-- To be used in Tableau visualization

SELECT location, population, date, MAX(total_cases) AS HighestInfectCount,  MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidProject.coviddeaths
WHERE continent <> ''
AND continent IS NOT NULL
AND location NOT IN ('world', 'Upper middle income', 'High income', 'Lower middle income', 'Low income', 'International', 'European Union', 'Asia')
GROUP BY location, population, date
ORDER BY location, date ASC;

-- Total Death Count per Country
-- To be used in Tableau visualization

SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM CovidProject.coviddeaths
WHERE continent = ''
AND location NOT IN ('world', 'Upper middle income', 'High income', 'Lower middle income', 'International', 'European Union', 'Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Total Death Count per Continent

SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM CovidProject.coviddeaths
WHERE continent = ''
AND location NOT IN ('world', 'Upper middle income', 'High income', 'Lower middle income', 'International', 'European Union', 'Low Income')
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS
-- To be used in Tableau visualization

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths, SUM(CAST(new_deaths AS UNSIGNED))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidProject.coviddeaths
WHERE continent <> ''
AND location NOT IN ('world', 'Upper middle income', 'High income', 'Lower middle income', 'International', 'European Union', 'Asia')
ORDER BY total_cases, total_deaths DESC;

-- TOTAL POPULATION VS VACCINATION
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
 SUM(CAST(VAC.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS RollingPeopleVaccinated  
FROM CovidProject.coviddeaths DEA
JOIN CovidProject.covidvaccinations VAC
	ON DEA.location = VAC.location
    AND DEA.date = VAC.date
WHERE DEA.continent <> ''
ORDER BY DEA.location, DEA.date;


-- Using CTE to perform calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
 SUM(CAST(VAC.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS RollingPeopleVaccinated  
FROM CovidProject.coviddeaths DEA
JOIN CovidProject.covidvaccinations VAC
	ON DEA.location = VAC.location
    AND DEA.date = VAC.date
WHERE DEA.continent <> ''
#ORDER BY DEA.location, DEA.date
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac;


-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE if exists PercentPopulationVaccinated
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date date,
Population unsigned,
New_vaccinations unsigned,
RollingPeopleVaccinated unsigned
)

INSERT INTO
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
 SUM(CAST(VAC.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS RollingPeopleVaccinated  
FROM CovidProject.coviddeaths DEA
JOIN CovidProject.covidvaccinations VAC
	ON DEA.location = VAC.location
    AND DEA.date = VAC.date
WHERE DEA.continent <> ''
#ORDER BY DEA.location, DEA.date

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PercentPopulationVaccinated;

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT new_viewDEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
 SUM(CAST(VAC.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS RollingPeopleVaccinated  
FROM CovidProject.coviddeaths DEA
JOIN CovidProject.covidvaccinations VAC
	ON DEA.location = VAC.location
    AND DEA.date = VAC.date
WHERE DEA.continent <> '';

