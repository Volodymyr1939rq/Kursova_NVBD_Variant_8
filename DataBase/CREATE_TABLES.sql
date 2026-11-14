USE InventoryManagement_OLTP
GO


CREATE TABLE dbo.Categories
(
CategoryID   INT IDENTITY(1,1) NOT NULL,
ParentCategoryID INT NULL,
CategoryName  NVARCHAR(100) NOT NULL,
Description   NVARCHAR(500) NULL,
CONSTRAINT PK_Categories PRIMARY KEY CLUSTERED (CategoryID)
);
GO

CREATE TABLE dbo.Warehouses(
WarehouseID   INT IDENTITY(1,1) NOT NULL,
WarehouseName NVARCHAR(100) NOT NULL,
City  NVARCHAR(100) NOT NULL,
Address NVARCHAR(100) NOT NULL,
CONSTRAINT PK_Warehouses PRIMARY KEY CLUSTERED (WarehouseID)
);
GO

CREATE TABLE dbo.Products(
ProductID  INT IDENTITY(1,1) NOT NULL,
SKU        VARCHAR(30) NOT NULL,
ProductName NVARCHAR(200) NOT NULL,
CategoryID  INT NOT NULL,
UnitsOfMeasure NVARCHAR(20) NOT NULL,
PurchasePrice DECIMAL(12,2) NOT NULL,
SellingPrice DECIMAL(12,2) NOT NULL,
MinStockLevel INT NOT NULL CONSTRAINT DF_Products_MinStock DEFAULT(10),
IsActive      BIT NOT NULL CONSTRAINT DF_Products_IsActive DEFAULT (1),
CreatedDate   DATETIME2(0) NOT NULL CONSTRAINT DF_Products_Created DEFAULT (SYSDATETIME()),
ModifiedDate  DATETIME2(0) NOT NULL CONSTRAINT DF_Products_Modified DEFAULT (SYSDATETIME()),
CONSTRAINT PK_Products PRIMARY KEY CLUSTERED (ProductID)
);
GO

CREATE TABLE dbo.Suppliers(
SupplierID    INT IDENTITY(1,1) NOT NULL,
CompanyName   NVARCHAR(150) NOT NULL,
TaxCode       VARCHAR(20) NOT NULL,
ContactPerson NVARCHAR(100) NULL,
Phone         VARCHAR(25) NOT NULL,
Email         VARCHAR(100) NULL,
City          NVARCHAR(100) NOT NULL,
Country       NVARCHAR(100) NOT NULL CONSTRAINT DF_Suppliers_Country DEFAULT (N'Україна'),
Rating        TINYINT NULL,
CreatedDate   DATETIME2(0) NOT NULL CONSTRAINT DF_Suppliers_Created DEFAULT (SYSDATETIME()),
CONSTRAINT PK_Suppliers PRIMARY KEY CLUSTERED (SupplierID)
);
GO

CREATE TABLE dbo.Customers(
CustomerID       INT IDENTITY(1,1) NOT NULL,
CustomerType     VARCHAR(20) NOT NULL, 
FullName         NVARCHAR(150) NOT NULL,
TaxCode          VARCHAR(20) NULL,
Phone            VARCHAR(25) NOT NULL,
Email            VARCHAR(100) NULL,
City             NVARCHAR(100) NOT NULL,
Region           NVARCHAR(100) NOT NULL,
DiscountPercent  DECIMAL(5, 2) NOT NULL CONSTRAINT DF_Customers_Discount DEFAULT (0.00),
RegistrationDate DATE NOT NULL,
ModifiedDate     DATETIME2(0) NOT NULL CONSTRAINT DF_Customers_Modified DEFAULT (SYSDATETIME()),
CONSTRAINT PK_Customers PRIMARY KEY CLUSTERED (CustomerID)
);
GO

CREATE TABLE dbo.Documents(
DocumentID     INT IDENTITY(1,1) NOT NULL,
DocumentNumber VARCHAR(30) NOT NULL,
OperationType  VARCHAR(20) NOT NULL, 
DocumentDate   DATETIME2(0) NOT NULL,
WarehouseID    INT NOT NULL,
SupplierID     INT NULL,
CustomerID     INT NULL,
Status         VARCHAR(20) NOT NULL CONSTRAINT DF_Documents_Status DEFAULT ('Completed'),
TotalAmount    DECIMAL(14, 2) NOT NULL CONSTRAINT DF_Documents_Total DEFAULT (0.00),
Notes          NVARCHAR(300) NULL,
ModifiedDate   DATETIME2(0) NOT NULL CONSTRAINT DF_Documents_Modified DEFAULT (SYSDATETIME()),
CONSTRAINT PK_Documents PRIMARY KEY CLUSTERED (DocumentID)
);
GO

CREATE TABLE dbo.OperationItems(
OperationItemID BIGINT IDENTITY(1,1) NOT NULL,
DocumentID      INT NOT NULL,
ProductID       INT NOT NULL,
Quantity        DECIMAL(12, 3) NOT NULL,
UnitPrice       DECIMAL(12, 2) NOT NULL,
DiscountAmount  DECIMAL(12, 2) NOT NULL CONSTRAINT DF_OperationItems_Discount DEFAULT (0.00),
LineTotal       AS (CAST((Quantity * UnitPrice) - DiscountAmount AS DECIMAL(14, 2))) PERSISTED,
CONSTRAINT PK_OperationItems PRIMARY KEY CLUSTERED (OperationItemID)
);
GO

CREATE TABLE dbo.Payments
(
PaymentID        BIGINT IDENTITY(1,1) NOT NULL,
DocumentID       INT NOT NULL,
PaymentDate      DATETIME2(0) NOT NULL,
PaymentDirection VARCHAR(10) NOT NULL, 
PaymentMethod    VARCHAR(30) NOT NULL,
Amount           DECIMAL(14, 2) NOT NULL,
TransactionRef   VARCHAR(50) NULL,
CONSTRAINT PK_Payments PRIMARY KEY CLUSTERED (PaymentID)
);
GO

CREATE TABLE dbo.InventoryBalances
(
WarehouseID    INT NOT NULL,
ProductID      INT NOT NULL,
QuantityOnHand DECIMAL(14, 3) NOT NULL CONSTRAINT DF_Balances_Qty DEFAULT (0.000),
LastUpdated    DATETIME2(0) NOT NULL CONSTRAINT DF_Balances_Updated DEFAULT (SYSDATETIME()),
CONSTRAINT PK_InventoryBalances PRIMARY KEY CLUSTERED (WarehouseID, ProductID)
);
GO
