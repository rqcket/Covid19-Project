--SELECT * 
--FROM PortfolioProject..CovidDeaths
--ORDER BY 3,4


-- Select Data that we will be using 

SELECT Location,date ,total_cases,new_cases,total_deaths,population
FROM PortfolioProject..CovidDeaths

-- Total Cases vs Total Deaths ( IMP CONVERSION )

Select location, date, total_cases,total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) AS "total_deaths/total_cases"
from PortfolioProject..covidDeaths
order by 1,2

--Death Percentage
-- Shows likelihood of dying in India
Select location, date, total_cases,total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))*100 AS DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%india%'
order by 1,2

-- Looking at total cases vs population

Select location, date, total_cases,total_deaths, population,
((NULLIF(CONVERT(float, total_cases),0))/population) *100 AS CasePercentage
from PortfolioProject..CovidDeaths
where location like '%india%'
order by 1,2

-- Highest Infection Rate compared to population

Select location, Population,MAX(total_cases) as HighestInfectionCount,
MAX((NULLIF(CONVERT(float, total_cases),0))/population) *100 AS PercentageInfected 
from PortfolioProject..CovidDeaths
group by location,population
order by 3 desc

-- Highest Death Count compared to population

Select location,MAX(cast(total_deaths as INT)) as HighestDeathCount,
MAX((NULLIF(CONVERT(float, total_deaths),0))/population) *100 AS DeathPercentage
from PortfolioProject..CovidDeaths
where continent is NULL
group by location
order by 3 desc

-- Global Numbers
-- Group By Date
Select date, SUM(new_cases) as total_cases ,SUM(cast(new_deaths as INT)) as total_deaths, 
(SUM(cast(new_deaths as INT))/SUM(new_cases))*100 AS DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
GROUP BY date
order by 1,2


--All time Covid19 Record
Select SUM(new_cases) as total_cases ,SUM(cast(new_deaths as INT)) as total_deaths, 
(SUM(cast(new_deaths as INT))/SUM(new_cases))*100 AS DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
--GROUP BY date
order by 1,2

--Covid Vaccinations

Select * 
FROM PortfolioProject..CovidVaccinations

-- Joining the 2 tables

-- Looking at Total Population vs Vaccination

Select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
on dea.location=vac.location and
dea.date=vac.date
where dea.continent is not null
order by 1,2,3

-- Sum of Vaccinations over time for each country

Select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as INT)) OVER (Partition BY dea.location ORDER by dea.location,dea.date) as TotalVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
on dea.location=vac.location and
dea.date=vac.date
where dea.continent is not null
order by 2,3

-- Total Vaccinations vs Population

Select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as INT)) OVER (Partition BY dea.location ORDER by dea.location,dea.date) as TotalVaccinations
--, (TotalVaccinations/Population)*100 --can't do this.. need to use CTE
FROM PortfolioProject..CovidDeaths dea, 
JOIN PortfolioProject..CovidVaccinations vac
on dea.location=vac.location and
dea.date=vac.date
where dea.continent is not null
order by 2,3

-- USE CTE 

With PopvsVac (Continent,Location,Date,Population,New_Vaccinations,TotalVaccinations)
as (
Select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as INT)) OVER (Partition BY dea.location ORDER by dea.location,dea.date) as TotalVaccinations
--, (TotalVaccinations/Population)*100 --can't do this.. need to use CTE
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
on dea.location=vac.location and
dea.date=vac.date
where dea.continent is not null 
--order by 2,3 
)
Select * ,(TotalVaccinations/Population)*100
from PopvsVac order by 2




-- USING TEMP TABLE

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Total_Vaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
Select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as INT)) OVER (Partition BY dea.location ORDER by dea.location,dea.date) as TotalVaccinations
--, (TotalVaccinations/Population)*100 --can't do this.. need to use CTE
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
on dea.location=vac.location and
dea.date=vac.date
where dea.continent is not null 
--order by 2,3 

Select * ,(Total_Vaccinations/Population)*100
from #PercentPopulationVaccinated order by 2,3

-- Creating View to store data visualisations later

CREATE VIEW PercentPeopleVaccinated as 
Select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as INT)) OVER (Partition BY dea.location ORDER by dea.location,dea.date) as TotalVaccinations
--, (TotalVaccinations/Population)*100 --can't do this.. need to use CTE
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
on dea.location=vac.location and
dea.date=vac.date
where dea.continent is not null 

SELECT *,(TotalVaccinations/Population)*100 as PercentPopulation
FROM PercentPeopleVaccinated 
order by 2
