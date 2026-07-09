USE AdventureWorks2012;
GO

SELECT TOP 10 *
FROM Person.Person;

SELECT TOP 10 *
FROM Sales.SalesOrderHeader;

SELECT TOP 10 *
FROM Sales.Customer;

SELECT TOP 10 *
FROM Person.EmailAddress;

SELECT TOP 10 *
FROM Person.PersonPhone;

SELECT TOP 10 *
FROM Person.PhoneNumberType;

--- a. Get all the details from the person table including email ID, phone number and phone number type

select e.EmailAddress as Email, p.BusinessEntityID,
    p.FirstName, p.LastName, ph.PhoneNumber, pt.Name as PhoneType from person.person p
Left join Person.EmailAddress e on p.BusinessEntityID = e.BusinessEntityID
LEFT JOIN Person.PersonPhone ph 
    ON p.BusinessEntityID = ph.BusinessEntityID
LEFT JOIN Person.PhoneNumberType pt 
    ON ph.PhoneNumberTypeID = pt.PhoneNumberTypeID
    
--- Get the details of the sales header order made in May 2011

SELECT
    SalesOrderID,
    OrderDate,
    CustomerID,
    TotalDue
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2011-05-01'
  AND OrderDate < '2011-06-01';

--- Get the details of the sales details order made in the month of May 2011

SELECT sod.*
FROM Sales.SalesOrderDetail sod
INNER JOIN Sales.SalesOrderHeader soh 
    ON sod.SalesOrderID = soh.SalesOrderID
WHERE soh.OrderDate >= '2011-05-01' 
  AND soh.OrderDate < '2011-06-01';

---Get the total sales made in May 2011

SELECT SUM(TotalDue) AS TotalSalesMay2011
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2011-05-01' 
  AND OrderDate < '2011-06-01';

---Get the total sales made in the year 2011 by month order by increasing sales

SELECT
    DATENAME(MONTH, OrderDate) AS OrderMonth,
    SUM(TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2011-01-01'
  AND OrderDate < '2012-01-01'
GROUP BY
    MONTH(OrderDate),
    DATENAME(MONTH, OrderDate)
ORDER BY TotalSales ASC;

--- Get the total sales made to the customer with FirstName='Gustavo' and LastName ='Achong'

SELECT 
    p.FirstName,
    p.LastName,
    SUM(soh.TotalDue) AS TotalSales
FROM Person.Person p
INNER JOIN Sales.Customer c 
    ON p.BusinessEntityID = c.PersonID
INNER JOIN Sales.SalesOrderHeader soh 
    ON c.CustomerID = soh.CustomerID
WHERE p.FirstName = 'Gustavo' 
  AND p.LastName = 'Achong'
GROUP BY p.FirstName, p.LastName;

--- Top 10 Customers by Total Sales

SELECT TOP 10
    p.FirstName,
    p.LastName,
    SUM(soh.TotalDue) AS TotalSales
FROM Person.Person p
JOIN Sales.Customer c
    ON p.BusinessEntityID = c.PersonID
JOIN Sales.SalesOrderHeader soh
    ON c.CustomerID = soh.CustomerID
GROUP BY p.FirstName, p.LastName
ORDER BY TotalSales DESC;

---Average Order Value

SELECT
AVG(TotalDue) AS AverageOrderValue
FROM Sales.SalesOrderHeader;

---Repeat Customers

SELECT
CustomerID,
COUNT(SalesOrderID) AS OrdersPlaced
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
HAVING COUNT(SalesOrderID)>1
ORDER BY OrdersPlaced DESC;

---Customers with No Orders
SELECT
c.CustomerID,
p.FirstName,
p.LastName
FROM Sales.Customer c
JOIN Person.Person p
ON c.PersonID=p.BusinessEntityID
LEFT JOIN Sales.SalesOrderHeader soh
ON c.CustomerID=soh.CustomerID
WHERE soh.SalesOrderID IS NULL;

---Top Selling Products

SELECT TOP 10
p.Name,
SUM(sod.OrderQty) AS QuantitySold
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod
ON p.ProductID=sod.ProductID
GROUP BY p.Name
ORDER BY QuantitySold DESC;

---Lowest Selling Products

SELECT TOP 10
p.Name,
SUM(sod.OrderQty) AS QuantitySold
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod
ON p.ProductID=sod.ProductID
GROUP BY p.Name
ORDER BY QuantitySold;

---Products Generating Highest Revenue
SELECT TOP 10
p.Name,
SUM(sod.LineTotal) AS Revenue
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod
ON p.ProductID=sod.ProductID
GROUP BY p.Name
ORDER BY Revenue DESC;


---Sales Analysis

--Quarterly Sales


SELECT
YEAR(OrderDate) AS Year,
DATEPART(QUARTER,OrderDate) AS Quarter,
SUM(TotalDue) AS Revenue
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate),DATEPART(QUARTER,OrderDate)
ORDER BY Year,Quarter;

---Year-over-Year Sales

SELECT
YEAR(OrderDate) AS SalesYear,
SUM(TotalDue) AS Revenue
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY SalesYear;

---Running Total

SELECT
OrderDate,
TotalDue,
SUM(TotalDue) OVER(
ORDER BY OrderDate
) AS RunningTotal
FROM Sales.SalesOrderHeader;


---Territory Analysis

--Sales by Region

SELECT
st.Name,
SUM(soh.TotalDue) AS Revenue
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesTerritory st
ON soh.TerritoryID=st.TerritoryID
GROUP BY st.Name
ORDER BY Revenue DESC;


----Salesperson Analysis
---Top Salespersons
SELECT TOP 10
sp.BusinessEntityID,
SUM(soh.TotalDue) AS Revenue
FROM Sales.SalesPerson sp
JOIN Sales.SalesOrderHeader soh
ON sp.BusinessEntityID=soh.SalesPersonID
GROUP BY sp.BusinessEntityID
ORDER BY Revenue DESC;

----Window Functions

---Rank Customers by Sales
SELECT
CustomerID,
SUM(TotalDue) AS Revenue,
RANK() OVER(
ORDER BY SUM(TotalDue) DESC
) AS CustomerRank
FROM Sales.SalesOrderHeader
GROUP BY CustomerID;

---Dense Rank Products
SELECT
p.Name,
SUM(sod.LineTotal) AS Revenue,
DENSE_RANK() OVER(
ORDER BY SUM(sod.LineTotal) DESC
) AS ProductRank
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod
ON p.ProductID=sod.ProductID
GROUP BY p.Name;


---Top Order per Customer

WITH Orders AS
(
SELECT
CustomerID,
SalesOrderID,
TotalDue,
ROW_NUMBER() OVER(
PARTITION BY CustomerID
ORDER BY TotalDue DESC
) AS rn
FROM Sales.SalesOrderHeader
)

SELECT *
FROM Orders
WHERE rn=1;

---SQL Views

CREATE VIEW vw_TopCustomers
AS
SELECT
    c.CustomerID,
    CONCAT(p.FirstName,' ',p.LastName) AS CustomerName,
    SUM(soh.TotalDue) AS TotalSales
FROM Sales.Customer c
JOIN Person.Person p
ON c.PersonID=p.BusinessEntityID
JOIN Sales.SalesOrderHeader soh
ON c.CustomerID=soh.CustomerID
GROUP BY
    c.CustomerID,
    p.FirstName,
    p.LastName;

SELECT *
FROM vw_TopCustomers;

---Stored Procedure

CREATE PROCEDURE usp_GetSalesByYear
    @Year INT
AS
BEGIN
    SELECT
        MONTH(OrderDate) AS SalesMonth,
        SUM(TotalDue) AS Revenue
    FROM Sales.SalesOrderHeader
    WHERE YEAR(OrderDate)=@Year
    GROUP BY MONTH(OrderDate)
    ORDER BY SalesMonth;
END;

EXEC usp_GetSalesByYear @Year=2011;
