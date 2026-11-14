USE InventoryManagement_OLTP;
GO
SET NOCOUNT ON;


INSERT INTO dbo.Categories (ParentCategoryID, CategoryName, Description)
VALUES
    (NULL, N'Електроніка', N'Комп''ютерна, мобільна та побутова електроніка'),
    (NULL, N'Побутова техніка', N'Велика та дрібна техніка для дому'),
    (NULL, N'Будівельні матеріали', N'Матеріали для ремонту та будівництва'),
    (NULL, N'Інструменти та обладнання', N'Ручний та електроінструмент'),
    (NULL, N'Офісні товари', N'Канцелярія та витратні матеріали для офісу'),
    (NULL, N'Автотовари', N'Автозапчастини, мастила та аксесуари'),
    (NULL, N'Меблі та інтер''єр', N'Офісні та домашні меблі'),
    (NULL, N'Спорт та туризм', N'Спорядження для спорту та активного відпочинку'),
    (NULL, N'Продукти харчування', N'Бакалія, напої та товари тривалого зберігання'),
    (NULL, N'Побутова хімія', N'Засоби для прибирання та гігієни');

;WITH Nums AS (
    SELECT TOP 40 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT INTO dbo.Categories (ParentCategoryID, CategoryName, Description)
SELECT
    ((n - 1) % 10) + 1,
    CONCAT(N'Підкатегорія №', n, N' (група ', ((n - 1) % 10) + 1, N')'),
    CONCAT(N'Спеціалізована товарна група рівня 2 — код ', n)
FROM Nums;
GO

INSERT INTO dbo.Warehouses (WarehouseName, City, Address)
VALUES
    (N'Центральний хаб Львів-1', N'Львів', N'вул. Городоцька, 285'),
    (N'Складський комплекс Київ-Північ', N'Київ', N'вул. Велика Кільцева, 42'),
    (N'Логістичний термінал Київ-Схід', N'Київ', N'вул. Бориспільська, 19'),
    (N'Регіональний склад Дніпро', N'Дніпро', N'просп. Слобожанський, 114'),
    (N'Термінал Одеса-Порт', N'Одеса', N'вул. Промислова, 31'),
    (N'Склад Харків-Індустріальний', N'Харків', N'просп. Героїв Харкова, 257'),
    (N'Розподільчий центр Вінниця', N'Вінниця', N'вул. Немирівське шосе, 88'),
    (N'Склад Івано-Франківськ', N'Івано-Франківськ', N'вул. Калуське шосе, 12'),
    (N'Термінал Тернопіль', N'Тернопіль', N'вул. Поліська, 7'),
    (N'Регіональний склад Рівне', N'Рівне', N'вул. Млинівська, 24');
GO

;WITH E1(N) AS (SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
                UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1),
      E2(N) AS (SELECT 1 FROM E1 a CROSS JOIN E1 b),
      E4(N) AS (SELECT 1 FROM E2 a CROSS JOIN E2 b),
      Nums AS (SELECT TOP 5000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM E4)
INSERT INTO dbo.Suppliers (CompanyName, TaxCode, ContactPerson, Phone, Email, City, Country, Rating, CreatedDate)
SELECT
    CONCAT(
        CASE n % 4 WHEN 0 THEN N'ТОВ "УкрПостач-' WHEN 1 THEN N'ПП "ГалТрейд-' WHEN 2 THEN N'ТОВ "ПромІмпорт-' ELSE N'ТзОВ "ЛогістикГруп-' END,
        n, N'"'
    ),
    RIGHT(CONCAT('30000000', n), 8),
    CONCAT(N'Менеджер Постачання №', n),
    CONCAT('+38067', RIGHT(CONCAT('0000000', n), 7)),
    CONCAT('supply', n, '@vendor-ua.com'),
    CASE n % 7
        WHEN 0 THEN N'Київ' WHEN 1 THEN N'Львів' WHEN 2 THEN N'Дніпро'
        WHEN 3 THEN N'Одеса' WHEN 4 THEN N'Харків' WHEN 5 THEN N'Вінниця' ELSE N'Луцьк'
    END,
    CASE WHEN n % 12 = 0 THEN N'Польща' WHEN n % 15 = 0 THEN N'Німеччина' ELSE N'Україна' END,
    (ABS(CHECKSUM(NEWID())) % 5) + 1,
    DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 365) - 1825, '2026-11-14')
FROM Nums;
GO

;WITH E1(N) AS (SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
                UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1),
      E2(N) AS (SELECT 1 FROM E1 a CROSS JOIN E1 b),
      E4(N) AS (SELECT 1 FROM E2 a CROSS JOIN E2 b),
      E8(N) AS (SELECT 1 FROM E4 a CROSS JOIN E4 b),
      Nums AS (SELECT TOP 55000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM E8)
INSERT INTO dbo.Customers (CustomerType, FullName, TaxCode, Phone, Email, City, Region, DiscountPercent, RegistrationDate)
SELECT
    CASE WHEN n % 4 = 0 THEN 'Company' ELSE 'Individual' END,
    CASE WHEN n % 4 = 0
         THEN CONCAT(N'ТОВ "БізнесКлієнт-', n, N'"')
         ELSE CONCAT(
             CASE n % 6 WHEN 0 THEN N'Коваленко ' WHEN 1 THEN N'Бондаренко ' WHEN 2 THEN N'Ткаченко '
                        WHEN 3 THEN N'Мельник ' WHEN 4 THEN N'Шевченко ' ELSE N'Кравчук ' END,
             N'Клієнт-', n
         )
    END,
    CASE WHEN n % 4 = 0 THEN RIGHT(CONCAT('40000000', n), 8) ELSE NULL END,
    CONCAT('+38050', RIGHT(CONCAT('0000000', n), 7)),
    CONCAT('customer', n, '@client.ua'),
    CASE n % 8
        WHEN 0 THEN N'Львів' WHEN 1 THEN N'Київ' WHEN 2 THEN N'Дніпро' WHEN 3 THEN N'Одеса'
        WHEN 4 THEN N'Харків' WHEN 5 THEN N'Вінниця' WHEN 6 THEN N'Тернопіль' ELSE N'Рівне'
    END,
    CASE n % 8
        WHEN 0 THEN N'Львівська область' WHEN 1 THEN N'Київська область' WHEN 2 THEN N'Дніпропетровська область' WHEN 3 THEN N'Одеська область'
        WHEN 4 THEN N'Харківська область' WHEN 5 THEN N'Вінницька область' WHEN 6 THEN N'Тернопільська область' ELSE N'Рівненська область'
    END,
    CASE (n % 5)
        WHEN 0 THEN 0.00 WHEN 1 THEN 3.00 WHEN 2 THEN 5.00 WHEN 3 THEN 10.00 ELSE 15.00
    END,
    DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 1825), '2026-11-14')
FROM Nums;
GO

;WITH E1(N) AS (SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
                UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1),
      E2(N) AS (SELECT 1 FROM E1 a CROSS JOIN E1 b),
      E4(N) AS (SELECT 1 FROM E2 a CROSS JOIN E2 b),
      E8(N) AS (SELECT 1 FROM E4 a CROSS JOIN E4 b),
      Nums AS (SELECT TOP 60000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM E8),
      BasePrices AS (
          SELECT
              n,
              11 + (n % 40) AS CatID,
              CAST(50.00 + (ABS(CHECKSUM(NEWID())) % 14950) + ((ABS(CHECKSUM(NEWID())) % 100) / 100.0) AS DECIMAL(12, 2)) AS BuyPrice,
              1.20 + ((ABS(CHECKSUM(NEWID())) % 46) / 100.0) AS MarkupMultiplier
          FROM Nums
      )
INSERT INTO dbo.Products (SKU, ProductName, CategoryID, UnitOfMeasure, PurchasePrice, SellingPrice, MinStockLevel, IsActive, CreatedDate)
SELECT
    CONCAT('SKU-', RIGHT(CONCAT('000000', n), 6)),
    CONCAT(N'Товар номенклатури #', n, N' (серія ', (n % 100) + 1, N')'),
    CatID,
    CASE n % 5 WHEN 0 THEN N'шт.' WHEN 1 THEN N'уп.' WHEN 2 THEN N'кг' WHEN 3 THEN N'компл.' ELSE N'м' END,
    BuyPrice,
    CAST(ROUND(BuyPrice * MarkupMultiplier, 2) AS DECIMAL(12, 2)),
    5 + (n % 25),
    CASE WHEN n % 25 = 0 THEN 0 ELSE 1 END,
    DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 365) - 1825, '2026-11-14')
FROM BasePrices;
GO