SELECT DISTINCT location
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY location

--Select *
--From PortfolioProject..CovidVaccinations
--order by 3, 4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

---- Check data type
--USE PortfolioProject; 
--SELECT 
--    COLUMN_NAME, 
--    DATA_TYPE
--FROM 
--    INFORMATION_SCHEMA.COLUMNS
--WHERE 
--    TABLE_NAME = 'CovidDeaths' -- Replace with your actual table name
--    AND COLUMN_NAME IN ('total_cases', 'total_deaths');

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying when contracting covid in your country
Select Location, date, total_cases, total_deaths, CONVERT(float, total_deaths) / CONVERT(float, total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
WHERE location like '%states%'
ORDER BY 1, 2

-- Looking at Total Cases vs Population
-- Shows the percentage of population contracted Covid
Select Location, date, total_cases, population, CONVERT(float, total_cases) / CONVERT(float, population)*100 AS CasesPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
WHERE location like '%states%'
ORDER BY 1, 2


-- Looking at Countries with Highest Infection Rate compared to Population
-- Shows the percentage of population contracted Covid
Select Location, population, MAX(CONVERT(int,total_cases)) AS HighestInfectionCount, MAX(CONVERT(float, total_cases) / CONVERT(float, population)*100) AS CasesPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
--WHERE location like '%states%'
GROUP BY location, population
ORDER BY CasesPercentage DESC

-- Showing Countries with Highest DeathCount per Population
SELECT Location, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
--WHERE location like '%states%'
GROUP BY location
ORDER BY TotalDeathCount DESC


-- view countries of continents
--SELECT continent, location
--FROM PortfolioProject..CovidDeaths
--GROUP BY continent, location
--ORDER BY continent;

-- Breakdown by Continent
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
   --AND continent NOT LIKE '%income%'
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- Global Numbers
Select date, SUM(new_cases), SUM(CONVERT(float, total_deaths)), SUM(CONVERT(float, total_deaths))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
Group By date
Order By 1, 2

SELECT date, SUM(new_cases) as total_cases, SUM(CONVERT(float, new_deaths)) as total_deaths, SUM(CONVERT(float, new_deaths)) / SUM(new_cases) * 100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

SELECT 
    date, 
    SUM(new_cases) as total_cases, 
    SUM(CONVERT(float, new_deaths)) as total_deaths, 
    CASE 
        WHEN SUM(new_cases) <> 0 AND SUM(CONVERT(float, new_deaths)) <> 0 THEN SUM(CONVERT(float, new_deaths)) / NULLIF(SUM(new_cases), 0) * 100
        ELSE 0 -- or any other default value you prefer
    END as DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
GROUP BY 
    date
ORDER BY 
    1,2;

--Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location 
	Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
order by 2,3


--USE CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location 
	Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population) *100
From PopvsVac


-- Temp table
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
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location 
	Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--WHERE dea.continent IS NOT NULL

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location 
	Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--order by 2,3

Select *
From PercentPopulationVaccinated