CREATE DATABASE InventoryManagement_DW;
GO

USE InventoryManagement_DW;
GO



CREATE TABLE dbo.DimDate (
    DateKey         INT          NOT NULL PRIMARY KEY, -- формат YYYYMMDD
    FullDate        DATE         NOT NULL,
    CalendarYear    SMALLINT     NOT NULL,
    CalendarQuarter TINYINT      NOT NULL,
    MonthNumber     TINYINT      NOT NULL,
    MonthName       NVARCHAR(20) NOT NULL,
    DayOfMonth      TINYINT      NOT NULL,
    DayOfWeekNumber TINYINT      NOT NULL,
    DayName         NVARCHAR(20) NOT NULL,
    IsWeekend       BIT          NOT NULL
);


CREATE TABLE dbo.DimProduct (
    ProductKey         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProductID          INT               NOT NULL, -- бізнес-ключ з OLTP
    SKU                VARCHAR(30)       NOT NULL,
    ProductName        NVARCHAR(200)     NOT NULL,
    CategoryName       NVARCHAR(100)     NOT NULL,
    ParentCategoryName NVARCHAR(100)     NOT NULL,
    UnitOfMeasure      NVARCHAR(20)      NOT NULL,
    PurchasePrice      DECIMAL(12, 2)    NOT NULL,
    SellingPrice       DECIMAL(12, 2)    NOT NULL,
    IsActive           BIT               NOT NULL,
    EffectiveFrom      DATETIME2(0)      NOT NULL,
    EffectiveTo        DATETIME2(0)      NULL,
    IsCurrent          BIT               NOT NULL DEFAULT (1)
);

CREATE TABLE dbo.DimWarehouse (
    WarehouseKey  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    WarehouseID   INT               NOT NULL,
    WarehouseName NVARCHAR(100)     NOT NULL,
    City          NVARCHAR(100)     NOT NULL,
    Address       NVARCHAR(100)     NOT NULL
);

CREATE TABLE dbo.DimCustomer (
    CustomerKey     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CustomerID      INT               NOT NULL,
    CustomerType    VARCHAR(20)       NOT NULL,
    FullName        NVARCHAR(150)     NOT NULL,
    City            NVARCHAR(100)     NOT NULL,
    Region          NVARCHAR(100)     NOT NULL,
    DiscountPercent DECIMAL(5, 2)     NOT NULL
);

CREATE TABLE dbo.DimSupplier (
    SupplierKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SupplierID  INT               NOT NULL,
    CompanyName NVARCHAR(150)     NOT NULL,
    City        NVARCHAR(100)     NOT NULL,
    Country     NVARCHAR(100)     NOT NULL,
    Rating      TINYINT           NULL
);

CREATE TABLE dbo.DimOperationType (
    OperationTypeKey  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    OperationTypeCode VARCHAR(20)       NOT NULL UNIQUE,
    OperationTypeName NVARCHAR(50)      NOT NULL,
    StockMultiplier   SMALLINT          NOT NULL -- +1 для IN, -1 для OUT/WRITEOFF
);
GO


CREATE TABLE dbo.FactInventoryOperations (
    FactOperationID   BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    OperationItemID   BIGINT               NOT NULL UNIQUE, -- для контролю дублікатів при інкременті
    DocumentNumber    VARCHAR(30)          NOT NULL,
    DateKey           INT                  NOT NULL FOREIGN KEY REFERENCES dbo.DimDate(DateKey),
    ProductKey        INT                  NOT NULL FOREIGN KEY REFERENCES dbo.DimProduct(ProductKey),
    WarehouseKey      INT                  NOT NULL FOREIGN KEY REFERENCES dbo.DimWarehouse(WarehouseKey),
    CustomerKey       INT                  NOT NULL FOREIGN KEY REFERENCES dbo.DimCustomer(CustomerKey),
    SupplierKey       INT                  NOT NULL FOREIGN KEY REFERENCES dbo.DimSupplier(SupplierKey),
    OperationTypeKey  INT                  NOT NULL FOREIGN KEY REFERENCES dbo.DimOperationType(OperationTypeKey),
    Quantity          DECIMAL(12, 3)       NOT NULL,
    UnitPrice         DECIMAL(12, 2)       NOT NULL,
    DiscountAmount    DECIMAL(12, 2)       NOT NULL,
    LineTotal         DECIMAL(14, 2)       NOT NULL,
    CostAmount        DECIMAL(14, 2)       NOT NULL, -- Quantity * PurchasePrice
    GrossProfit       DECIMAL(14, 2)       NOT NULL  -- прибуток від продажу (для OUT)
);

CREATE TABLE dbo.FactPayments (
    FactPaymentID    BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PaymentID        BIGINT               NOT NULL UNIQUE,
    DocumentNumber   VARCHAR(30)          NOT NULL,
    DateKey          INT                  NOT NULL FOREIGN KEY REFERENCES dbo.DimDate(DateKey),
    WarehouseKey     INT                  NOT NULL FOREIGN KEY REFERENCES dbo.DimWarehouse(WarehouseKey),
    CustomerKey      INT                  NOT NULL FOREIGN KEY REFERENCES dbo.DimCustomer(CustomerKey),
    SupplierKey      INT                  NOT NULL FOREIGN KEY REFERENCES dbo.DimSupplier(SupplierKey),
    OperationTypeKey INT                  NOT NULL FOREIGN KEY REFERENCES dbo.DimOperationType(OperationTypeKey),
    PaymentDirection VARCHAR(10)          NOT NULL,
    PaymentMethod    VARCHAR(30)          NOT NULL,
    PaymentAmount    DECIMAL(14, 2)       NOT NULL
);
GO


CREATE TABLE dbo.ETLAuditLog (
    AuditID       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PackageName   NVARCHAR(100)     NOT NULL,
    StartTime     DATETIME2(0)      NOT NULL DEFAULT (SYSDATETIME()),
    EndTime       DATETIME2(0)      NULL,
    RowsExtracted INT               NOT NULL DEFAULT (0),
    RowsInserted  INT               NOT NULL DEFAULT (0),
    RowsUpdated   INT               NOT NULL DEFAULT (0),
    RowsRejected  INT               NOT NULL DEFAULT (0),
    Status        VARCHAR(20)       NOT NULL DEFAULT ('Running'),
    ErrorMessage  NVARCHAR(1000)    NULL
);

CREATE TABLE dbo.ETLErrorRows (
    ErrorID          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PackageName      NVARCHAR(100)        NOT NULL,
    TaskName         NVARCHAR(100)        NOT NULL,
    SourceRecordID   VARCHAR(50)          NULL,
    ErrorDescription NVARCHAR(500)        NOT NULL,
    LoggedAt         DATETIME2(0)         NOT NULL DEFAULT (SYSDATETIME())
);

CREATE TABLE dbo.ETLWatermark (
    TableName      VARCHAR(50)  NOT NULL PRIMARY KEY,
    LastLoadedID   BIGINT       NOT NULL DEFAULT (0),
    LastLoadedDate DATETIME2(0) NOT NULL DEFAULT ('2000-01-01')
);
GO

CREATE NONCLUSTERED INDEX IX_DimProduct_BusinessKey ON dbo.DimProduct(ProductID, IsCurrent);
CREATE NONCLUSTERED INDEX IX_DimCustomer_BusinessKey ON dbo.DimCustomer(CustomerID);
CREATE NONCLUSTERED INDEX IX_DimSupplier_BusinessKey ON dbo.DimSupplier(SupplierID);
CREATE NONCLUSTERED INDEX IX_FactOps_DateKey ON dbo.FactInventoryOperations(DateKey);
CREATE NONCLUSTERED INDEX IX_FactOps_ProductKey ON dbo.FactInventoryOperations(ProductKey);
CREATE NONCLUSTERED INDEX IX_FactOps_WarehouseKey ON dbo.FactInventoryOperations(WarehouseKey);
CREATE NONCLUSTERED INDEX IX_FactPayments_DateKey ON dbo.FactPayments(DateKey);
GO