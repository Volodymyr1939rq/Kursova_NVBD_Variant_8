USE InventoryManagement_OLTP;
GO

ALTER TABLE dbo.Categories
    ADD CONSTRAINT FK_Categories_Parent FOREIGN KEY (ParentCategoryID) REFERENCES dbo.Categories(CategoryID);

ALTER TABLE dbo.Products
    ADD CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID) REFERENCES dbo.Categories(CategoryID);

ALTER TABLE dbo.Documents
    ADD CONSTRAINT FK_Documents_Warehouses FOREIGN KEY (WarehouseID) REFERENCES dbo.Warehouses(WarehouseID),
        CONSTRAINT FK_Documents_Suppliers  FOREIGN KEY (SupplierID)  REFERENCES dbo.Suppliers(SupplierID),
        CONSTRAINT FK_Documents_Customers  FOREIGN KEY (CustomerID)  REFERENCES dbo.Customers(CustomerID);

ALTER TABLE dbo.OperationItems
    ADD CONSTRAINT FK_OperationItems_Documents FOREIGN KEY (DocumentID) REFERENCES dbo.Documents(DocumentID),
        CONSTRAINT FK_OperationItems_Products  FOREIGN KEY (ProductID)  REFERENCES dbo.Products(ProductID);

ALTER TABLE dbo.Payments
    ADD CONSTRAINT FK_Payments_Documents FOREIGN KEY (DocumentID) REFERENCES dbo.Documents(DocumentID);

ALTER TABLE dbo.InventoryBalances
    ADD CONSTRAINT FK_Balances_Warehouses FOREIGN KEY (WarehouseID) REFERENCES dbo.Warehouses(WarehouseID),
        CONSTRAINT FK_Balances_Products   FOREIGN KEY (ProductID)   REFERENCES dbo.Products(ProductID);
GO

ALTER TABLE dbo.Categories ADD CONSTRAINT UQ_Categories_Name UNIQUE (CategoryName);
ALTER TABLE dbo.Warehouses ADD CONSTRAINT UQ_Warehouses_Name UNIQUE (WarehouseName);
ALTER TABLE dbo.Products   ADD CONSTRAINT UQ_Products_SKU UNIQUE (SKU);
ALTER TABLE dbo.Suppliers  ADD CONSTRAINT UQ_Suppliers_TaxCode UNIQUE (TaxCode);
ALTER TABLE dbo.Documents  ADD CONSTRAINT UQ_Documents_Number UNIQUE (DocumentNumber);
GO

ALTER TABLE dbo.Products
    ADD CONSTRAINT CK_Products_Prices CHECK (PurchasePrice >= 0 AND SellingPrice >= 0),
        CONSTRAINT CK_Products_MinStock CHECK (MinStockLevel >= 0);

ALTER TABLE dbo.Suppliers
    ADD CONSTRAINT CK_Suppliers_Rating CHECK (Rating BETWEEN 1 AND 5 OR Rating IS NULL);

ALTER TABLE dbo.Customers
    ADD CONSTRAINT CK_Customers_Type CHECK (CustomerType IN ('Individual', 'Company')),
        CONSTRAINT CK_Customers_Discount CHECK (DiscountPercent BETWEEN 0 AND 100);

ALTER TABLE dbo.Documents
    ADD CONSTRAINT CK_Documents_OpType CHECK (OperationType IN ('IN', 'OUT', 'WRITEOFF')),
        CONSTRAINT CK_Documents_Status CHECK (Status IN ('Draft', 'Completed', 'Cancelled')),
        CONSTRAINT CK_Documents_Total CHECK (TotalAmount >= 0),
        CONSTRAINT CK_Documents_Counterparty CHECK (
            (OperationType = 'IN'       AND SupplierID IS NOT NULL AND CustomerID IS NULL) OR
            (OperationType = 'OUT'      AND CustomerID IS NOT NULL AND SupplierID IS NULL) OR
            (OperationType = 'WRITEOFF' AND SupplierID IS NULL     AND CustomerID IS NULL)
        );

ALTER TABLE dbo.OperationItems
    ADD CONSTRAINT CK_OperationItems_Qty CHECK (Quantity > 0),
        CONSTRAINT CK_OperationItems_Price CHECK (UnitPrice >= 0),
        CONSTRAINT CK_OperationItems_Discount CHECK (DiscountAmount >= 0 AND DiscountAmount <= Quantity * UnitPrice);

ALTER TABLE dbo.Payments
    ADD CONSTRAINT CK_Payments_Direction CHECK (PaymentDirection IN ('Incoming', 'Outgoing')),
        CONSTRAINT CK_Payments_Method CHECK (PaymentMethod IN ('Cash', 'Card', 'BankTransfer')),
        CONSTRAINT CK_Payments_Amount CHECK (Amount > 0);

ALTER TABLE dbo.InventoryBalances
    ADD CONSTRAINT CK_Balances_NonNegative CHECK (QuantityOnHand >= 0);
GO

CREATE NONCLUSTERED INDEX IX_Products_CategoryID ON dbo.Products(CategoryID) INCLUDE (ProductName, SellingPrice, IsActive);
CREATE NONCLUSTERED INDEX IX_Documents_Date_Type ON dbo.Documents(DocumentDate, OperationType) INCLUDE (WarehouseID, SupplierID, CustomerID, TotalAmount, Status);
CREATE NONCLUSTERED INDEX IX_Documents_SupplierID ON dbo.Documents(SupplierID) WHERE SupplierID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Documents_CustomerID ON dbo.Documents(CustomerID) WHERE CustomerID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_OperationItems_DocumentID ON dbo.OperationItems(DocumentID) INCLUDE (ProductID, Quantity, LineTotal);
CREATE NONCLUSTERED INDEX IX_OperationItems_ProductID ON dbo.OperationItems(ProductID) INCLUDE (DocumentID, Quantity, LineTotal);
CREATE NONCLUSTERED INDEX IX_Payments_DocumentID ON dbo.Payments(DocumentID) INCLUDE (PaymentDate, Amount, PaymentDirection);
GO