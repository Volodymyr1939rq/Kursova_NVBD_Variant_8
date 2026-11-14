USE InventoryManagement_OLTP;
GO

CREATE OR ALTER FUNCTION dbo.fn_GetDocumentDebt (@DocumentID INT)
RETURNS DECIMAL(14, 2)
AS
BEGIN
    DECLARE @Debt DECIMAL(14, 2);

    SELECT @Debt = d.TotalAmount - ISNULL((
        SELECT SUM(p.Amount) FROM dbo.Payments p WHERE p.DocumentID = d.DocumentID
    ), 0.00)
    FROM dbo.Documents d
    WHERE d.DocumentID = @DocumentID;

    RETURN ISNULL(@Debt, 0.00);
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CreateSingleItemDocument
    @DocumentNumber VARCHAR(30),
    @OperationType  VARCHAR(20),
    @DocumentDate   DATETIME2(0),
    @WarehouseID    INT,
    @SupplierID     INT = NULL,
    @CustomerID     INT = NULL,
    @ProductID      INT,
    @Quantity       DECIMAL(12, 3),
    @UnitPrice      DECIMAL(12, 2),
    @DiscountAmount DECIMAL(12, 2) = 0.00
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @NewDocID INT;

        INSERT INTO dbo.Documents (DocumentNumber, OperationType, DocumentDate, WarehouseID, SupplierID, CustomerID, Status)
        VALUES (@DocumentNumber, @OperationType, @DocumentDate, @WarehouseID, @SupplierID, @CustomerID, 'Completed');

        SET @NewDocID = SCOPE_IDENTITY();

        INSERT INTO dbo.OperationItems (DocumentID, ProductID, Quantity, UnitPrice, DiscountAmount)
        VALUES (@NewDocID, @ProductID, @Quantity, @UnitPrice, @DiscountAmount);

        COMMIT TRANSACTION;
        SELECT @NewDocID AS CreatedDocumentID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RecalculateAllBalances
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE dbo.InventoryBalances;

    INSERT INTO dbo.InventoryBalances (WarehouseID, ProductID, QuantityOnHand, LastUpdated)
    SELECT
        d.WarehouseID,
        oi.ProductID,
        SUM(CASE WHEN d.OperationType = 'IN' THEN oi.Quantity ELSE -oi.Quantity END) AS QuantityOnHand,
        SYSDATETIME()
    FROM dbo.OperationItems oi
    INNER JOIN dbo.Documents d ON oi.DocumentID = d.DocumentID
    WHERE d.Status = 'Completed'
    GROUP BY d.WarehouseID, oi.ProductID
    HAVING SUM(CASE WHEN d.OperationType = 'IN' THEN oi.Quantity ELSE -oi.Quantity END) >= 0;
END;
GO