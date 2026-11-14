USE InventoryManagement_OLTP;
GO

CREATE OR ALTER TRIGGER dbo.TR_OperationItems_SyncBalancesAndTotals
ON dbo.OperationItems
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;  

  
    ;WITH AffectedDocs AS (
        SELECT DocumentID FROM inserted
        UNION
        SELECT DocumentID FROM deleted
    )
    UPDATE d
    SET d.TotalAmount = ISNULL((
            SELECT SUM(oi.LineTotal)
            FROM dbo.OperationItems oi
            WHERE oi.DocumentID = d.DocumentID
        ), 0.00),
        d.ModifiedDate = SYSDATETIME()
    FROM dbo.Documents d
    INNER JOIN AffectedDocs ad ON d.DocumentID = ad.DocumentID;

    ;WITH Deltas AS (
        SELECT
            d.WarehouseID,
            i.ProductID,
            SUM(CASE WHEN d.OperationType = 'IN' THEN i.Quantity ELSE -i.Quantity END) AS QtyDelta
        FROM inserted i
        INNER JOIN dbo.Documents d ON i.DocumentID = d.DocumentID
        WHERE d.Status = 'Completed'
        GROUP BY d.WarehouseID, i.ProductID

        UNION ALL

        SELECT
            d.WarehouseID,
            del.ProductID,
            SUM(CASE WHEN d.OperationType = 'IN' THEN -del.Quantity ELSE del.Quantity END) AS QtyDelta
        FROM deleted del
        INNER JOIN dbo.Documents d ON del.DocumentID = d.DocumentID
        WHERE d.Status = 'Completed'
        GROUP BY d.WarehouseID, del.ProductID
    ),
    AggregatedDeltas AS (
        SELECT WarehouseID, ProductID, SUM(QtyDelta) AS NetDelta
        FROM Deltas
        GROUP BY WarehouseID, ProductID
        HAVING SUM(QtyDelta) <> 0
    )
    MERGE dbo.InventoryBalances AS target
    USING AggregatedDeltas AS source
    ON (target.WarehouseID = source.WarehouseID AND target.ProductID = source.ProductID)
    WHEN MATCHED THEN
        UPDATE SET
            target.QuantityOnHand = target.QuantityOnHand + source.NetDelta,
            target.LastUpdated = SYSDATETIME()
    WHEN NOT MATCHED BY TARGET AND source.NetDelta > 0 THEN
        INSERT (WarehouseID, ProductID, QuantityOnHand, LastUpdated)
        VALUES (source.WarehouseID, source.ProductID, source.NetDelta, SYSDATETIME());

END;
GO


CREATE OR ALTER TRIGGER dbo.TR_Payments_ValidateAmount
ON dbo.Payments
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM dbo.Documents d
        INNER JOIN (SELECT DISTINCT DocumentID FROM inserted) ins ON d.DocumentID = ins.DocumentID
        CROSS APPLY (
            SELECT ISNULL(SUM(p.Amount), 0) AS PaidTotal
            FROM dbo.Payments p
            WHERE p.DocumentID = d.DocumentID
        ) pay
        WHERE pay.PaidTotal > d.TotalAmount
    )
    BEGIN
        RAISERROR(N'Помилка бізнес-правила: сума платежів за документом перевищує суму накладної.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO