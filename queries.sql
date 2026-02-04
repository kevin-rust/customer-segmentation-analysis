/* 
Customer Segmentation Analysis
Database: CustomerSegmentation
Dataset: Online Retail
*/

/* ================================
   Step 1: Data Exploration
================================ */

-- Total rows before cleaning
SELECT COUNT(*) AS TotalRows
FROM online_retail;

-- Null CustomerIDs
SELECT COUNT(*) AS NullCustomers
FROM online_retail
WHERE CustomerID IS NULL;

-- Negative quantities (returns)
SELECT COUNT(*) AS NegativeQty
FROM online_retail
WHERE Quantity <= 0;

-- Cancelled invoices
SELECT COUNT(*) AS CancelledInvoices
FROM online_retail
WHERE InvoiceNo LIKE 'C%';



/* ================================
   Step 2: Data Cleaning
================================ */

-- Remove cancelled invoices
DELETE FROM online_retail
WHERE InvoiceNo LIKE 'C%';

-- Remove returned orders
DELETE FROM online_retail
WHERE Quantity <= 0;

-- Remove missing CustomerIDs
DELETE FROM online_retail
WHERE CustomerID IS NULL;



/* ================================
   Step 3: Create Revenue Column
================================ */

ALTER TABLE online_retail
ADD TotalPrice AS (Quantity * UnitPrice);



/* ================================
   Step 4: Customer-Level Aggregation
================================ */

-- Create customer summary table
SELECT 
    CustomerID,
    CAST(SUM(TotalPrice) AS DECIMAL(18,2)) AS TotalSpend,
    COUNT(DISTINCT InvoiceNo) AS OrderCount,
    CAST(SUM(TotalPrice) / COUNT(DISTINCT InvoiceNo) AS DECIMAL(18,2)) AS AvgOrderValue
INTO customer_summary
FROM online_retail
GROUP BY CustomerID;



/* ================================
   Step 5: Customer Segmentation
================================ */

-- Create spend tiers
SELECT 
    CustomerID,
    TotalSpend,
    OrderCount,
    AvgOrderValue,
    NTILE(3) OVER (ORDER BY TotalSpend DESC) AS SpendTier
INTO customer_segments
FROM customer_summary;



-- Label segments
SELECT 
    CustomerID,
    TotalSpend,
    OrderCount,
    AvgOrderValue,
    CASE 
        WHEN SpendTier = 1 THEN 'High Value'
        WHEN SpendTier = 2 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS CustomerSegment
INTO customer_segments_labeled
FROM customer_segments;



/* ================================
   Step 6: Segment Analysis
================================ */

-- Revenue distribution by segment
SELECT 
    CustomerSegment,
    COUNT(*) AS CustomersInSegment,
    SUM(TotalSpend) AS SegmentRevenue,
    CAST(100.0 * SUM(TotalSpend) / 
        (SELECT SUM(TotalSpend) FROM customer_segments_labeled) 
        AS DECIMAL(5,2)) AS RevenuePercentage
FROM customer_segments_labeled
GROUP BY CustomerSegment
ORDER BY RevenuePercentage DESC;
