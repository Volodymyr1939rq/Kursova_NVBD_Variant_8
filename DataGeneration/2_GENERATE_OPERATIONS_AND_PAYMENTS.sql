USE InventoryManagement_OLTP;
GO
SET NOCOUNT ON;

DISABLE TRIGGER dbo.TR_OperationItems_SyncBalancesAndTotals ON dbo.OperationItems;
DISABLE TRIGGER dbo.TR_Payments_ValidateAmount ON dbo.Payments;
GO

TRUNCATE TABLE dbo.Payments;
TRUNCATE TABLE dbo.InventoryBalances;
TRUNCATE TABLE dbo.OperationItems;
GO

ALTER INDEX IX_OperationItems_DocumentID ON dbo.OperationItems DISABLE;
ALTER INDEX IX_OperationItems_ProductID ON dbo.OperationItems DISABLE;
GO

;WITH E1(N) AS (SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
                UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1),
      E2(N) AS (SELECT 1 FROM E1 a CROSS JOIN E1 b),
      E4(N) AS (SELECT 1 FROM E2 a CROSS JOIN E2 b),
      E8(N) AS (SELECT 1 FROM E4 a CROSS JOIN E4 b),
      Nums AS (SELECT TOP 250000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM E8),
      RawItems AS (
          SELECT
              ((n - 1) % 60000) + 1 AS DocID,
              ((CAST(n AS BIGINT) * 7919 + 101) % 60000) + 1 AS ProdID,
              CAST(80 + (n % 221) AS DECIMAL(12, 3)) AS Qty
          FROM Nums
      )
INSERT INTO dbo.OperationItems WITH (TABLOCK) (DocumentID, ProductID, Quantity, UnitPrice, DiscountAmount)
SELECT r.DocID, r.ProdID, r.Qty, p.PurchasePrice, 0.00
FROM RawItems r
INNER JOIN dbo.Products p ON r.ProdID = p.ProductID;
GO

;WITH E1(N) AS (SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
                UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1),
      E2(N) AS (SELECT 1 FROM E1 a CROSS JOIN E1 b),
      E4(N) AS (SELECT 1 FROM E2 a CROSS JOIN E2 b),
      E8(N) AS (SELECT 1 FROM E4 a CROSS JOIN E4 b),
      Nums AS (SELECT TOP 850000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM E8),
      RawItems AS (
          SELECT
              60001 + ((CAST(n AS BIGINT) * 104729 + 37) % 240000) AS DocID,
              ((CAST(n AS BIGINT) * 7919 + 503) % 60000) + 1 AS ProdID,
              CAST(1 + (n % 5) AS DECIMAL(12, 3)) AS Qty
          FROM Nums
      )
INSERT INTO dbo.OperationItems WITH (TABLOCK) (DocumentID, ProductID, Quantity, UnitPrice, DiscountAmount)
SELECT
    r.DocID,
    r.ProdID,
    r.Qty,
    p.SellingPrice,
    CAST(ROUND(r.Qty * p.SellingPrice * (ISNULL(c.DiscountPercent, 0) / 100.0), 2) AS DECIMAL(12, 2))
FROM RawItems r
INNER JOIN dbo.Products p ON r.ProdID = p.ProductID
INNER JOIN dbo.Documents d ON r.DocID = d.DocumentID
LEFT JOIN dbo.Customers c ON d.CustomerID = c.CustomerID;
GO

;WITH E1(N) AS (SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
                UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1),
      E2(N) AS (SELECT 1 FROM E1 a CROSS JOIN E1 b),
      E4(N) AS (SELECT 1 FROM E2 a CROSS JOIN E2 b),
      E8(N) AS (SELECT 1 FROM E4 a CROSS JOIN E4 b),
      Nums AS (SELECT TOP 50000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM E8),
      RawItems AS (
          SELECT
              300001 + ((CAST(n AS BIGINT) * 9973 + 11) % 20000) AS DocID,
              ((CAST(n AS BIGINT) * 7919 + 997) % 60000) + 1 AS ProdID,
              CAST(1 + (n % 3) AS DECIMAL(12, 3)) AS Qty
          FROM Nums
      )
INSERT INTO dbo.OperationItems WITH (TABLOCK) (DocumentID, ProductID, Quantity, UnitPrice, DiscountAmount)
SELECT r.DocID, r.ProdID, r.Qty, p.PurchasePrice, 0.00
FROM RawItems r
INNER JOIN dbo.Products p ON r.ProdID = p.ProductID;
GO

;WITH BalanceCheck AS (
    SELECT
        d.WarehouseID,
        oi.ProductID,
        SUM(CASE WHEN d.OperationType = 'IN' THEN oi.Quantity ELSE -oi.Quantity END) AS NetQty
    FROM dbo.OperationItems oi
    INNER JOIN dbo.Documents d ON oi.DocumentID = d.DocumentID
    GROUP BY d.WarehouseID, oi.ProductID
    HAVING SUM(CASE WHEN d.OperationType = 'IN' THEN oi.Quantity ELSE -oi.Quantity END) < 0
),
WarehouseInDoc AS (
    SELECT WarehouseID, MIN(DocumentID) AS SampleInDocID
    FROM dbo.Documents
    WHERE OperationType = 'IN'
    GROUP BY WarehouseID
)
INSERT INTO dbo.OperationItems (DocumentID, ProductID, Quantity, UnitPrice, DiscountAmount)
SELECT w.SampleInDocID, b.ProductID, ABS(b.NetQty) + 50.000, p.PurchasePrice, 0.00
FROM BalanceCheck b
INNER JOIN WarehouseInDoc w ON b.WarehouseID = w.WarehouseID
INNER JOIN dbo.Products p ON b.ProductID = p.ProductID;
GO

ALTER INDEX IX_OperationItems_DocumentID ON dbo.OperationItems REBUILD;
ALTER INDEX IX_OperationItems_ProductID ON dbo.OperationItems REBUILD;
GO

;WITH DocTotals AS (
    SELECT DocumentID, SUM(LineTotal) AS CalcTotal
    FROM dbo.OperationItems
    GROUP BY DocumentID
)
UPDATE d
SET d.TotalAmount = dt.CalcTotal
FROM dbo.Documents d
INNER JOIN DocTotals dt ON d.DocumentID = dt.DocumentID;
GO

EXEC dbo.usp_RecalculateAllBalances;
GO

INSERT INTO dbo.Payments WITH (TABLOCK) (DocumentID, PaymentDate, PaymentDirection, PaymentMethod, Amount, TransactionRef)
SELECT
    d.DocumentID,
    DATEADD(HOUR, 1 + (d.DocumentID % 72), d.DocumentDate),
    CASE WHEN d.OperationType = 'IN' THEN 'Outgoing' ELSE 'Incoming' END,
    CASE d.DocumentID % 3 WHEN 0 THEN 'BankTransfer' WHEN 1 THEN 'Card' ELSE 'Cash' END,
    CASE
        WHEN d.DocumentID % 20 IN (0, 1) THEN CAST(ROUND(d.TotalAmount * 0.50, 2) AS DECIMAL(14, 2))
        ELSE d.TotalAmount
    END,
    CONCAT('TRX-', d.DocumentID, '-', (d.DocumentID * 37) % 100000)
FROM dbo.Documents d
WHERE d.OperationType IN ('IN', 'OUT')
  AND d.TotalAmount > 0
  AND (d.DocumentID % 20) NOT IN (17, 18, 19);
GO

ENABLE TRIGGER dbo.TR_OperationItems_SyncBalancesAndTotals ON dbo.OperationItems;
ENABLE TRIGGER dbo.TR_Payments_ValidateAmount ON dbo.Payments;
GO