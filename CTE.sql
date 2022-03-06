/*
CTE Practice queries
*/
-- Create a table and populate data in to it
CREATE TABLE tbAlmondData (AlmondDate DATE, AlmondValue DECIMAL(13,2))
 
DECLARE @startdate DATE = '1988-12-01', @value DECIMAL(13,2)
 
WHILE @startdate <= '2019-01-01'
BEGIN
  SET @value = ((RAND()*100))
 
  INSERT INTO tbAlmondData VALUES (@startdate,@value)
 
  SET @startdate = DATEADD(MM,1,@startdate)
END

---- Simple aggregate query 

SELECT
	MAX(AlmondDate) LatestDate,
	MIN(AlmondDate) EarliestDate, 
	COUNT(AlmondDate) CountofValues
FROM 
	tbAlmondData;

--- Find the average almond value by Year. Original table has only date
-- Find the AlmondYear from date and make it as first wrapped query and use it later to group
WITH GroupAlmondDates AS(
  SELECT 
    YEAR(AlmondDate) AlmondYear
    , AlmondDate
    , AlmondValue
    , (AlmondValue*10) Base10AlmondValue
  FROM tbAlmondData
), AvgAlmond AS(
	SELECT AVG(AlmondValue) AvgAlmondValue -- without column name, this query won't execute
	FROM GroupAlmondDates
	Group BY AlmondYear)

SELECT TOP 10 * FROM AvgAlmond order by AvgAlmondValue;

-- Recursive CTE

WITH cte_numbers(n, weekday) 
AS (
    SELECT 
        0, 
        DATENAME(DW, 0)
    UNION ALL
    SELECT    
        n + 1, 
        DATENAME(DW, n + 1)
    FROM    
        cte_numbers
    WHERE n < 6
)
SELECT 
    weekday
FROM 
    cte_numbers;
-----------------------------------------------
------------- CREATE VIEW FROM CTE ------------

USE AdventureWorks2019;
GO
drop view if exists vwCTE
go
CREATE VIEW vwCTE AS
WITH cte as
(
    SELECT BusinessEntityID,NationalIDNumber
    FROM HumanResources.Employee
    WHERE CurrentFlag = 1
)
-- Notice the MAXRECURSION option is removed
SELECT GETDATE() as TodayDate
GO

--- Aggregation on aggregation
WITH min_max_grade AS (
SELECT      su.id,
        MIN (e.grade) AS min_grade,
        MAX (e.grade) AS max_grade
FROM subjects su JOIN exams e ON su.id = e.subject_id
GROUP BY su.id, su.subject_name
)
 
SELECT      AVG (min_grade) AS avg_min_grade,
        AVG (max_grade) AS avg_max_grade
FROM min_max_grade;


----- recursive CTE further example

-- Create an Employee table.  
CREATE TABLE dbo.MyEmployees  
(  
EmployeeID SMALLINT NOT NULL,  
FirstName NVARCHAR(30)  NOT NULL,  
LastName  NVARCHAR(40) NOT NULL,  
Title NVARCHAR(50) NOT NULL,  
DeptID SMALLINT NOT NULL,  
ManagerID SMALLINT NULL,  
 CONSTRAINT PK_EmployeeID PRIMARY KEY CLUSTERED (EmployeeID ASC),
 CONSTRAINT FK_MyEmployees_ManagerID_EmployeeID FOREIGN KEY (ManagerID) REFERENCES dbo.MyEmployees (EmployeeID)
);  
-- Populate the table with values.  
INSERT INTO dbo.MyEmployees VALUES   
 (1, N'Ken', N'Sánchez', N'Chief Executive Officer',16,NULL)  
,(273, N'Brian', N'Welcker', N'Vice President of Sales',3,1)  
,(274, N'Stephen', N'Jiang', N'North American Sales Manager',3,273)  
,(275, N'Michael', N'Blythe', N'Sales Representative',3,274)  
,(276, N'Linda', N'Mitchell', N'Sales Representative',3,274)  
,(285, N'Syed', N'Abbas', N'Pacific Sales Manager',3,273)  
,(286, N'Lynn', N'Tsoflias', N'Sales Representative',3,285)  
,(16,  N'David',N'Bradley', N'Marketing Manager', 4, 273)  
,(23,  N'Mary', N'Gibson', N'Marketing Specialist', 4, 16);


WITH DirectReports(ManagerID, EmployeeID, Title, EmployeeLevel) AS   
(  
    SELECT ManagerID, EmployeeID, Title, 0 AS EmployeeLevel  
    FROM dbo.MyEmployees   
    WHERE ManagerID IS NULL  
    UNION ALL  
    SELECT e.ManagerID, e.EmployeeID, e.Title, EmployeeLevel + 1  
    FROM dbo.MyEmployees AS e  
        INNER JOIN DirectReports AS d  
        ON e.ManagerID = d.EmployeeID   
)  
SELECT ManagerID, EmployeeID, Title, EmployeeLevel   
FROM DirectReports  
ORDER BY EmployeeLevel;

--Creates an infinite loop  
WITH cte (EmployeeID, ManagerID, Title) AS  
(  
    SELECT EmployeeID, ManagerID, Title  
    FROM dbo.MyEmployees  
    WHERE ManagerID IS NOT NULL  
  UNION ALL
    SELECT cte.EmployeeID, cte.ManagerID, cte.Title  
    FROM cte   
    JOIN  dbo.MyEmployees AS e   
        ON cte.ManagerID = e.EmployeeID  
)  
--Uses MAXRECURSION to limit the recursive levels to 2  
SELECT EmployeeID, ManagerID, Title  
FROM cte  
OPTION (MAXRECURSION 2);


SELECT *
    FROM dbo.MyEmployees  
    WHERE ManagerID IS NOT NULL  

WITH employee_chain AS (
  SELECT
    EmployeeID,
    FirstName,
    LastName,
    CAST(CONCAT(FirstName,' ' ,LastName) AS varchar(255)) AS chain
  FROM dbo.MyEmployees
  WHERE ManagerID IS NULL
  UNION ALL
  SELECT
    emp.EmployeeID,
    emp.FirstName,
    emp.LastName,
    CAST(CONCAT(chain,'->',emp.FirstName,' ' ,emp.LastName) AS varchar(255))
  FROM employee_chain
  JOIN MyEmployees emp
    ON emp.ManagerID = .EmployeeID
)
 
SELECT *
FROM employee_chain;