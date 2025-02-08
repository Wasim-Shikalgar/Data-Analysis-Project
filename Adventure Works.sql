# Union of Fact Internet sales and Fact internet sales new
CREATE TABLE fact_internet_sales_union AS
SELECT * FROM fact_internet_sales_new
UNION ALL
SELECT * FROM fact_internet_sales;
SELECT * FROM fact_internet_sales_union;

# Lookup the productname from the Product sheet to Sales sheet.
SELECT 
    fsu.*,
    p.EnglishProductName
FROM fact_internet_sales_union fsu
JOIN Products p ON fsu.ProductKey = p.ProductKey;

# Lookup the Customerfullname from the Customer and Unit Price from Product sheet to Sales sheet.
SELECT 
    fsu.*,
    p.EnglishProductName,
    p.Unitprice,
    CONCAT(
        COALESCE(c.Title, ''), ' ',
        COALESCE(c.FirstName, ''), ' ',
        COALESCE(c.MiddleName, ''), ' ',
        COALESCE(c.LastName, '')
		   ) AS CustomerFullName
FROM fact_internet_sales_union fsu
JOIN Products p ON fsu.ProductKey = p.ProductKey
JOIN Customers c ON fsu.CustomerKey = c.CustomerKey;

/* calcuate the following fields from the Orderdatekey field ( First Create a Date Field from Orderdatekey)
   A.Year
   B.Monthno
   C.Monthfullname
   D.Quarter(Q1,Q2,Q3,Q4)
   E. YearMonth ( YYYY-MMM)
   F. Weekdayno
   G.Weekdayname
   H.FinancialMOnth
   I. Financial Quarter */
SELECT 
     *,
	 YEAR(OrderDate) AS Year,
     MONTH(OrderDate) AS MonthNo,
	 MONTHNAME(OrderDate) AS MonthFullName,
     CONCAT('Q', QUARTER(OrderDate)) AS Quarter_,
     DATE_FORMAT(OrderDate, '%Y-%b') AS YearMonth,
     DAYOFWEEK(OrderDate) AS WeekdayNo,
     DAYNAME(OrderDate) AS WeekdayName,
     CASE 
         WHEN MONTH(OrderDate) >= 4 THEN 
              MONTH(OrderDate) - 3
         ELSE 
              MONTH(OrderDate) + 9
     END AS FinancialMonth,
     CASE 
         WHEN MONTH(OrderDate) BETWEEN 4 AND 6 THEN 'Q1'
         WHEN MONTH(OrderDate) BETWEEN 7 AND 9 THEN 'Q2'
         WHEN MONTH(OrderDate) BETWEEN 10 AND 12 THEN 'Q3'
         ELSE 'Q4'
     END AS FinancialQuarter
FROM fact_internet_sales_union;

# Calculate the Sales amount uning the columns(unit price,order quantity,unit discount)
SELECT *, (UnitPrice * OrderQuantity) * (1 - UnitPriceDiscountPct) AS Sales FROM fact_internet_sales_union;

# Calculate the Productioncost uning the columns(unit cost ,order quantity)
SELECT *, ProductStandardCost * OrderQuantity AS ProductionCost, (UnitPrice * OrderQuantity) * (1 - UnitPriceDiscountPct) AS Sales FROM fact_internet_sales_union;

# Calculate the profit.
SELECT *,
       ProductStandardCost * OrderQuantity AS ProductionCost,
	   (UnitPrice * OrderQuantity) * (1 - UnitPriceDiscountPct) AS Sales,
       ((UnitPrice * OrderQuantity) * (1 - UnitPriceDiscountPct)) - (ProductStandardCost * OrderQuantity) AS Profit
FROM fact_internet_sales_union;

# Create a Pivot table for month and sales (provide the Year as filter to select a particular Year)
SELECT
    MONTH(Orderdate) AS Month_,
    SUM((UnitPrice * OrderQuantity) * (1 - UnitPriceDiscountPct)) AS Sales
FROM 
    fact_internet_sales_union
WHERE 
    YEAR(Orderdate) = 2013
GROUP BY 
    MONTH(Orderdate)
ORDER BY 
    MONTH(Orderdate);

# Create a Bar chart to show yearwise Sales
SELECT 
    YEAR(Orderdate) AS Year,
    SUM((UnitPrice * OrderQuantity) * (1 - UnitPriceDiscountPct)) AS Sales
FROM 
    fact_internet_sales_union
GROUP BY 
    YEAR(Orderdate)
ORDER BY 
    YEAR(Orderdate);

# Create a Line Chart to show Monthwise sales
SELECT 
    MONTH(Orderdate) AS Month,
    SUM((UnitPrice * OrderQuantity) * (1 - UnitPriceDiscountPct)) AS Sales
FROM 
    fact_internet_sales_union
GROUP BY 
    MONTH(Orderdate)
ORDER BY 
    MONTH(Orderdate);

# Create a Pie chart to show Quarterwise sales
SELECT 
    QUARTER(Orderdate) AS Quarter_,
    SUM((UnitPrice * OrderQuantity) * (1 - UnitPriceDiscountPct)) AS Sales
FROM 
    fact_internet_sales_union
GROUP BY 
    QUARTER(Orderdate)
ORDER BY 
    QUARTER(Orderdate);

# Create a combinational chart (bar and Line) to show Salesamount and Productioncost together
SELECT 
    MONTH(Orderdate) AS Month,
    SUM((UnitPrice * OrderQuantity) * (1 - UnitPriceDiscountPct)) AS Sales,
    SUM(ProductStandardCost * OrderQuantity) AS ProductionCost
FROM 
    fact_internet_sales_union
GROUP BY 
    MONTH(Orderdate)
ORDER BY 
    MONTH(Orderdate);

# Build addtional KPI /Charts for Performance by Products, Customers, Region
SELECT 
    p.ProductKey, 
    p.EnglishProductName, 
    SUM((fsu.UnitPrice * fsu.OrderQuantity) * (1 - fsu.UnitPriceDiscountPct)) AS Sales,
     SUM(fsu.ProductStandardCost * fsu.OrderQuantity) AS ProductionCost,
    SUM(((fsu.UnitPrice * fsu.OrderQuantity) * (1 - fsu.UnitPriceDiscountPct)) - (fsu.ProductStandardCost * fsu.OrderQuantity)) AS Profit
FROM 
    fact_internet_sales_union fsu
JOIN 
    products p ON fsu.ProductKey = p.ProductKey
GROUP BY 
    p.ProductKey, p.EnglishProductName
ORDER BY 
    Sales DESC
Limit 10;

SELECT 
    st.SalesTerritoryRegion AS Region,
    SUM((fsu.UnitPrice * fsu.OrderQuantity) * (1 - fsu.UnitPriceDiscountPct)) AS Sales,
	SUM(fsu.ProductStandardCost * fsu.OrderQuantity) AS ProductionCost,
    SUM(((fsu.UnitPrice * fsu.OrderQuantity) * (1 - fsu.UnitPriceDiscountPct)) - (fsu.ProductStandardCost * fsu.OrderQuantity)) AS Profit
FROM 
    fact_internet_sales_union fsu
JOIN 
    salesterritories st ON fsu.SalesTerritoryKey = st.SalesTerritoryKey
GROUP BY 
    st.SalesTerritoryRegion
ORDER BY 
    Sales DESC;

SELECT 
    c.CustomerKey,
   CONCAT(
        COALESCE(c.Title, ''), ' ',
        COALESCE(c.FirstName, ''), ' ',
        COALESCE(c.MiddleName, ''), ' ',
        COALESCE(c.LastName, '')
		   ) AS CustomerName,
    SUM((fsu.UnitPrice * fsu.OrderQuantity) * (1 - fsu.UnitPriceDiscountPct)) AS Sales,
    SUM(((fsu.UnitPrice * fsu.OrderQuantity) * (1 - fsu.UnitPriceDiscountPct)) - (fsu.ProductStandardCost * fsu.OrderQuantity)) AS Profit
FROM 
    fact_internet_sales_union fsu
JOIN 
    customers c ON fsu.CustomerKey = c.CustomerKey
GROUP BY 
    c.CustomerKey, CustomerName
ORDER BY 
    Sales DESC;