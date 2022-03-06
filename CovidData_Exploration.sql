/*
Project : Data Exploration Using Sql
DataSet : Covid-19 Data from https://ourworldindata.org/
Sql features used : 
	1. Joins
	2. CTE
	3. Window Functions
	4. Views
	5. Temp tables

Data Imported using sql import/export wizard
*/

---------------------------------------------- EXPLORE THE DATA LOADED --------------------------------------------
select top 1000 * 
from [dbo].[CovidDeaths]
where location = 'San Marino'


select top 1000 * 
from [dbo].[CovidVaccinations]

------------------------------------------- ***** Total Cases vs Total Deaths ***** -------------------------------------- 
-- latest 2 weeks
-- Current likelihood of dying if you contract covid based on country
-- Considering Just US and India here

Select 
	Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathRate
From 
	Portfolio..CovidDeaths
Where 
	location in ('India','United States')
	and continent is not null 
	and total_deaths > 0 
	and [date] > DATEADD(dd, -14, GETDATE())
order by 
	Location asc,[date] desc

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------- COVID INFECTION RATE BY COUNTRY---------------------------------------------

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid in each country. 
-- % of new_case to population
-- Showing the latest data first

Select 
	Location, date, Population, total_cases,  (new_cases/population)*100 as CurrInfectionRate
From 
	Portfolio..CovidDeaths
order by 
	[date] desc,Location asc


---- Countries with Highest Percentage of Population Infected till now

Select 
	Location, Population, 
	MAX(total_cases) as HighestInfectionCount,  
	Max((total_cases/population))*100 as PercentPopulationInfected
From 
	Portfolio..CovidDeaths
--where location = 'India'
Group by Location, Population
order by PercentPopulationInfected desc

------------------ Countries with Highest Death Count -----------------
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Portfolio..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc

--- Countries with highest death rate -----

------------------ Countries with Highest Death % till today -----------------
Select Location, total_Deaths/total_cases  * 100 as TotalDeathRate
From Portfolio..CovidDeaths
--Where location like '%states%'
Where continent is not null 
and [date] = (select max([date]) from Portfolio..CovidDeaths)
--Group by Location
order by TotalDeathRate desc


---------- BY CONTINENT -----------------

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Portfolio..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Portfolio..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2
-----------------------------------------------------------------------------------------------------------------------
-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select 
d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CAST(ISNULL(v.new_vaccinations,0) AS bigint)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
From Portfolio..CovidDeaths d
Join Portfolio..CovidVaccinations v On d.location = v.location and d.date = v.date
where d.continent is not null and new_vaccinations is not null
order by 2,3

-- Find Percentage of people vaccinated
-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select 
d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CAST(ISNULL(v.new_vaccinations,0) AS bigint)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
From Portfolio..CovidDeaths d
Join Portfolio..CovidVaccinations v On d.location = v.location and d.date = v.date
where d.continent is not null and new_vaccinations is not null
)
Select *, FORMAT((RollingPeopleVaccinated/Population)*100,'N2') as '% RollingPeopleVaccinated'
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select 
d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CAST(ISNULL(v.new_vaccinations,0) AS bigint)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
From Portfolio..CovidDeaths d
Join Portfolio..CovidVaccinations v On d.location = v.location and d.date = v.date
where d.continent is not null and new_vaccinations is not null

--- Percentage of people vaccinated
Select 
	Location,MAX(Date) as LatestDataAvailable,
	MAX(FORMAT((RollingPeopleVaccinated/Population)*100,'N2')) as 'PercentPeopleVaccinated'
From #PercentPopulationVaccinated
group by Location
order by PercentPeopleVaccinated asc

------------------- Creating View to store data for later visualizations----------------------------------

Create View 
	PercentPopulationVaccinated 
as
Select 
d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CAST(ISNULL(v.new_vaccinations,0) AS bigint)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
From 
	Portfolio..CovidDeaths d
	Join Portfolio..CovidVaccinations v On d.location = v.location and d.date = v.date
where 
	d.continent is not null and new_vaccinations is not null
