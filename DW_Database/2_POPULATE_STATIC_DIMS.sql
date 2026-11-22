USE InventoryManagement_DW;
GO
SET NOCOUNT ON;

SET IDENTITY_INSERT dbo.DimCustomer ON;
IF NOT EXISTS (SELECT 1 FROM dbo.DimCustomer WHERE CustomerKey = -1)
    INSERT INTO dbo.DimCustomer (CustomerKey, CustomerID, CustomerType, FullName, City, Region, DiscountPercent)
    VALUES (-1, -1, 'N/A', N'Не застосовується (прихід/списання)', N'Не вказано', N'Не вказано', 0.00);
SET IDENTITY_INSERT dbo.DimCustomer OFF;

SET IDENTITY_INSERT dbo.DimSupplier ON;
IF NOT EXISTS (SELECT 1 FROM dbo.DimSupplier WHERE SupplierKey = -1)
    INSERT INTO dbo.DimSupplier (SupplierKey, SupplierID, CompanyName, City, Country, Rating)
    VALUES (-1, -1, N'Не застосовується (реалізація/списання)', N'Не вказано', N'Не вказано', NULL);
SET IDENTITY_INSERT dbo.DimSupplier OFF;
GO

INSERT INTO dbo.DimOperationType (OperationTypeCode, OperationTypeName, StockMultiplier)
VALUES
    ('IN',       N'Прихід товару від постачальника',  1),
    ('OUT',      N'Реалізація товару покупцю',       -1),
    ('WRITEOFF', N'Акт списання товару',             -1);
GO

;WITH DateSeq AS (
    SELECT CAST('2021-01-01' AS DATE) AS dt
    UNION ALL
    SELECT DATEADD(DAY, 1, dt)
    FROM DateSeq
    WHERE dt < '2027-12-31'
)
INSERT INTO dbo.DimDate (
    DateKey, FullDate, CalendarYear, CalendarQuarter, MonthNumber,
    MonthName, DayOfMonth, DayOfWeekNumber, DayName, IsWeekend
)
SELECT
    YEAR(dt) * 10000 + MONTH(dt) * 100 + DAY(dt),
    dt,
    YEAR(dt),
    DATEPART(QUARTER, dt),
    MONTH(dt),
    CASE MONTH(dt)
        WHEN 1 THEN N'Січень' WHEN 2 THEN N'Лютий' WHEN 3 THEN N'Березень'
        WHEN 4 THEN N'Квітень' WHEN 5 THEN N'Травень' WHEN 6 THEN N'Червень'
        WHEN 7 THEN N'Липень' WHEN 8 THEN N'Серпень' WHEN 9 THEN N'Вересень'
        WHEN 10 THEN N'Жовтень' WHEN 11 THEN N'Листопад' ELSE N'Грудень'
    END,
    DAY(dt),
    ((DATEPART(WEEKDAY, dt) + @@DATEFIRST - 2) % 7) + 1, -- 1=Пн .. 7=Нд
    CASE ((DATEPART(WEEKDAY, dt) + @@DATEFIRST - 2) % 7) + 1
        WHEN 1 THEN N'Понеділок' WHEN 2 THEN N'Вівторок' WHEN 3 THEN N'Середа'
        WHEN 4 THEN N'Четвер' WHEN 5 THEN N'П''ятниця' WHEN 6 THEN N'Субота' ELSE N'Неділя'
    END,
    CASE WHEN ((DATEPART(WEEKDAY, dt) + @@DATEFIRST - 2) % 7) + 1 IN (6, 7) THEN 1 ELSE 0 END
FROM DateSeq
OPTION (MAXRECURSION 3000);
GO

INSERT INTO dbo.ETLWatermark (TableName, LastLoadedID, LastLoadedDate)
VALUES
    ('DimWarehouse', 0, '2000-01-01'),
    ('DimSupplier',  0, '2000-01-01'),
    ('DimCustomer',  0, '2000-01-01'),
    ('DimProduct',   0, '2000-01-01'),
    ('FactInventoryOperations', 0, '2000-01-01'),
    ('FactPayments', 0, '2000-01-01');
GO