USE InventoryManagement_OLTP;
GO

-- 1. Перевірка кількості записів у всіх таблицях (Етап 2.4)
SELECT 'Categories' AS TableName, COUNT(*) AS RecordCount FROM dbo.Categories
UNION ALL SELECT 'Warehouses', COUNT(*) FROM dbo.Warehouses
UNION ALL SELECT 'Suppliers', COUNT(*) FROM dbo.Suppliers
UNION ALL SELECT 'Customers', COUNT(*) FROM dbo.Customers
UNION ALL SELECT 'Products', COUNT(*) FROM dbo.Products
UNION ALL SELECT 'Documents', COUNT(*) FROM dbo.Documents
UNION ALL SELECT 'OperationItems', COUNT(*) FROM dbo.OperationItems
UNION ALL SELECT 'Payments', COUNT(*) FROM dbo.Payments
UNION ALL SELECT 'InventoryBalances', COUNT(*) FROM dbo.InventoryBalances;

-- 2. Перевірка часового діапазону (має бути ~5 років) та цілісності залишків
SELECT
    MIN(DocumentDate) AS MinDate,
    MAX(DocumentDate) AS MaxDate,
    DATEDIFF(YEAR, MIN(DocumentDate), MAX(DocumentDate)) AS YearsSpan
FROM dbo.Documents;

SELECT COUNT(*) AS NegativeBalancesCount
FROM dbo.InventoryBalances
WHERE QuantityOnHand < 0; -- має бути 0

-- 3. Тестування продуктивності аналітичного запиту на 1 150 000+ рядках (для звіту)
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT TOP 10
    c.CategoryName,
    SUM(oi.Quantity) AS TotalSoldQty,
    SUM(oi.LineTotal) AS TotalRevenue
FROM dbo.OperationItems oi
INNER JOIN dbo.Documents d ON oi.DocumentID = d.DocumentID
INNER JOIN dbo.Products p ON oi.ProductID = p.ProductID
INNER JOIN dbo.Categories c ON p.CategoryID = c.CategoryID
WHERE d.OperationType = 'OUT'
  AND d.DocumentDate >= '2025-01-01'
GROUP BY c.CategoryName
ORDER BY TotalRevenue DESC;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO