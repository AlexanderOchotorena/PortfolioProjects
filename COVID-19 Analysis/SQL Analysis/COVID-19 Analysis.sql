--Project 2, Covid-19 Data Analysis


--Looking at TotalCases V TotalDeaths.
--The location percentage you could die if you contracted COVID-19.
SELECT
	continent,
	Location,
	date,
	population,
	total_cases,
	new_cases,
	total_deaths,
	ROUND((CAST(total_deaths as float) / CAST(total_cases as float)) * 100,2 ) AS Death_Percentage
FROM
	CovidProject..CovidDeaths
WHERE
	continent IS NOT NULL
ORDER BY
	1,2


--Look at total_population V total_cases.
SELECT
	Location,
	population,
	Max(CAST(total_cases as int)) as totalcases,
	MAX(ROUND(( total_cases / population) * 100, 2)) AS Percent_Of_Population_Infected
FROM
	CovidProject..CovidDeaths
WHERE
	location IS NOT NULL AND 
	population IS NOT NULL
GROUP BY
	Location,
	population
ORDER BY
	4 DESC
 

--Showing the total death count per location.
SELECT
	Location,
	population,
	MAX(cast(total_deaths AS INT)) AS Total_Death_Count
FROM
	CovidProject..CovidDeaths
WHERE
	continent IS NOT NULL
GROUP BY
	location,
	population
ORDER BY
	Total_Death_Count DESC


--Show The total death count per continent and income.
SELECT
	location,
	MAX(cast(total_deaths AS INT)) AS total_death_count
FROM
	CovidProject..CovidDeaths
WHERE
	continent IS NULL
GROUP BY
	location
ORDER BY
	total_death_count DESC


--The Global chance to die if you contract covid.
SELECT
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS int)) AS total_deaths,
	ROUND(SUM(CAST(new_deaths as int)) / sum(new_cases), 3 ) * 100 AS DeathPercentage
FROM
	CovidProject..CovidDeaths
WHERE
	continent IS not NULL
ORDER BY
	1,2


--Looking at Population V Vaccinations.


--First I created a temptable to store the columns that would be in it.
Drop table if exists #RollingPeopleVac
CREATE TABLE #RollingPeopleVac(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	RollingPeopleVaccinated numeric
	
)


-- I then Inserted the data of the rolling count into the temp table.
INSERT INTO #RollingPeopleVac 
	SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
		sum(convert(bigint, CV.new_vaccinations)) OVER (Partition by CD.location ORDER BY CD.date ROWS UNBOUNDED PRECEDING) AS RollingPeopleVaccinated
	FROM
		CovidProject..CovidDeaths AS CD
	JOIN 
	CovidProject..CovidVaccinations AS CV 
	ON CD.date = CV.date AND CD.location = CV.location
	WHERE 
		CD.continent is not null AND 
		population is not null


--Next we will then Find the rolling percent of people vaccinated then put that into a temp table.
DROP TABLE IF exists #rolling_per
CREATE TABLE #rolling_per(
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	RollingPeopleVaccinated numeric,
	rolling_percent float
)


--We then insert the query into the temptable.
INSERT INTO #rolling_per
	SELECT 
		location,
		date,
		population,
		new_vaccinations,
		RollingPeopleVaccinated,
		((RollingPeopleVaccinated / population) * 100) AS rolling_percent
	FROM
		#RollingPeopleVac
	GROUP BY
		location,
		date,
		population,
		new_vaccinations,
		RollingPeopleVaccinated
	Order BY 
		1,2 


--Last we get the total of percentage of people vaccinated per location.
SELECT
	location,
	population,
	MAX(RollingPeopleVaccinated) AS TotalPeopleVaccinated,
	MAX(rolling_percent) AS TotalPercentageOfPeopleVaccinated
FROM 
	#rolling_per
GROUP BY
	location,
	population
ORDER BY
	4 DESC 


--Need to create a table to store for later visualizations.
DROP TABLE IF exists TotalPeopleVaccinated
CREATE TABLE TotalPeopleVaccinated (
	Location nvarchar(255),
	Population numeric,
	TotalPeopleVaccinated numeric,
	TotalPercentageOfPeopleVaccinated float
)


--Inserting Into the table.
INSERT INTO TotalPeopleVaccinated
	SELECT
		location,
		population,
		MAX(RollingPeopleVaccinated) AS TotalPeopleVaccinated,
		MAX(rolling_percent) AS TotalPercentageOfPeopleVaccinated
	FROM 
		#rolling_per
	GROUP BY
		location,
		population
	ORDER BY
		4 DESC 



--Now I will create Multiple Views to store for later visualizations. 

CREATE VIEW TotalCasesVTotalDeaths AS
	SELECT
		continent,
		Location,
		date,
		population,
		total_cases,
		new_cases,
		total_deaths,
		ROUND((CAST(total_deaths as float) / CAST(total_cases as float)) * 100,2 ) AS Death_Percentage
	FROM
		CovidProject..CovidDeaths
	WHERE
		continent IS NOT NULL


CREATE VIEW TotalPopulationVTotalCases AS
	SELECT
		Location,
		population,
		Max(CAST(total_cases as int)) as totalcases,
		MAX(ROUND(( total_cases / population) * 100, 2)) AS Percent_Of_Population_Infected
	FROM
		CovidProject..CovidDeaths
	WHERE
		location IS NOT NULL AND 
		population IS NOT NULL
	GROUP BY
		Location,
		population


CREATE VIEW HighestDeathCountPerLocation AS
	SELECT
		Location,
		population,
		MAX(cast(total_deaths AS INT)) AS Total_Death_Count
	FROM
		CovidProject..CovidDeaths
	WHERE
		continent IS NOT NULL
	GROUP BY
		location,
		population


CREATE VIEW HighestDeathCountPerContinentandIncome AS
	SELECT
		location,
		MAX(cast(total_deaths AS INT)) AS total_death_count
	FROM
		CovidProject..CovidDeaths
	WHERE
		continent IS NULL
	GROUP BY
		location