--1. Выберите сотрудников, которые являются продажниками, и еще не сделали ни одной продажи.

SELECT
	PersonID
 ,FullName
FROM Application.People
WHERE IsSalesperson = 1
AND PersonID NOT IN (SELECT
		SalespersonPersonID
	FROM Sales.Orders
	WHERE SalespersonPersonID IS NOT NULL);

WITH cte
AS
(SELECT
		SalespersonPersonID
	FROM Sales.Orders
	WHERE SalespersonPersonID IS NOT NULL)
SELECT
	PersonID
 ,FullName
FROM Application.People
WHERE IsSalesperson = 1
AND PersonID NOT IN (SELECT
		cte.SalespersonPersonID
	FROM cte);

--2. Выберите товары с минимальной ценой (подзапросом), 2 варианта подзапроса.

SELECT
	StockItemID
 ,StockItemName
FROM Warehouse.StockItems
WHERE UnitPrice = (SELECT
		MIN(UnitPrice)
	FROM Warehouse.StockItems);

WITH cte
AS
(SELECT
		MIN(UnitPrice) AS MinPrice
	FROM Warehouse.StockItems)
SELECT
	StockItemID
 ,StockItemName
FROM Warehouse.StockItems
JOIN cte
	ON UnitPrice = cte.MinPrice;
--3. Выберите информацию по клиентам, которые перевели компании 5 максимальных платежей из [Sales].[CustomerTransactions] представьте 3 способа (в том числе с CTE)

SELECT TOP (5)
	Customers.CustomerID
 ,CustomerName
 ,TransactionAmount
FROM Sales.CustomerTransactions
JOIN Sales.Customers
	ON CustomerTransactions.CustomerID = Customers.CustomerID
ORDER BY TransactionAmount DESC;

SELECT
	Customers.CustomerID
 ,CustomerName
 ,TransactionAmount
FROM Sales.Customers
JOIN (SELECT TOP (5)
		CustomerID
	 ,TransactionAmount
	FROM Sales.CustomerTransactions
	ORDER BY TransactionAmount DESC) AS [Transaction]
	ON Customers.CustomerID = [Transaction].CustomerID;


WITH cte
AS
(SELECT TOP (5)
		CustomerID
	 ,TransactionAmount
	FROM Sales.CustomerTransactions
	ORDER BY TransactionAmount DESC)
SELECT DISTINCT
	Customers.CustomerID
 ,CustomerName
 ,TransactionAmount
FROM Sales.Customers
JOIN cte
	ON Customers.CustomerID = cte.CustomerID

--4. Выберите города (ид и название), в которые были доставлены товары, входящие в тройку самых дорогих товаров, а также Имя сотрудника, который осуществлял упаковку заказов

SELECT DISTINCT
	CityID
 ,CityName
 ,FullName AS PackedBy
FROM Sales.Invoices
JOIN Sales.Customers
	ON Invoices.CustomerID = Customers.CustomerID
JOIN Application.Cities
	ON Customers.DeliveryCityID = Cities.CityID
JOIN Application.People
	ON Invoices.PackedByPersonID = People.PersonID
JOIN Sales.InvoiceLines
	ON Invoices.InvoiceID = InvoiceLines.InvoiceID
WHERE ConfirmedReceivedBy IS NOT NULL
AND StockItemID IN (SELECT TOP 3
		StockItemID
	FROM Warehouse.StockItems
	ORDER BY UnitPrice DESC)

WITH cte
AS
(SELECT TOP 3
		StockItemID
	FROM Warehouse.StockItems
	ORDER BY UnitPrice DESC)
SELECT DISTINCT
	CityID
 ,CityName
 ,FullName AS PackedBy
FROM Sales.Invoices
JOIN Sales.Customers
	ON Invoices.CustomerID = Customers.CustomerID
JOIN Application.Cities
	ON Customers.DeliveryCityID = Cities.CityID
JOIN Application.People
	ON Invoices.PackedByPersonID = People.PersonID
JOIN Sales.InvoiceLines
	ON Invoices.InvoiceID = InvoiceLines.InvoiceID
JOIN cte
	ON InvoiceLines.StockItemID = cte.StockItemID
WHERE ConfirmedReceivedBy IS NOT NULL;

--5. Объясните, что делает и оптимизируйте запрос:
/*SELECT
	Invoices.InvoiceID
 ,Invoices.InvoiceDate
 ,(SELECT
			People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID)
	AS SalesPersonName
 ,SalesTotals.TotalSumm AS TotalSummByInvoice
 ,(SELECT
			SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT
				Orders.OrderId
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL
			AND Orders.OrderId = Invoices.OrderId))
	AS TotalSummForPickedItems
FROM Sales.Invoices
JOIN (SELECT
		InvoiceId
	 ,SUM(Quantity * UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity * UnitPrice) > 27000) AS SalesTotals
	ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC*/

--добавлен cte
WITH SalesTotals
AS
(SELECT
		InvoiceId
	 ,SUM(Quantity * UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity * UnitPrice) > 27000)
SELECT
  Invoices.InvoiceID
 ,Invoices.InvoiceDate
 ,People.FullName AS SalesPersonName
	--сделан джойн заместо подзапроса
 ,SalesTotals.TotalSumm AS TotalSummByInvoice
 ,(SELECT
 --выносить в cte смысла нет запрос начинает работать медленей
			SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice) AS ItemsSum
		FROM Sales.OrderLines
		JOIN Sales.Orders
			ON OrderLines.OrderID = Orders.OrderID
		WHERE Orders.PickingCompletedWhen IS NOT NULL)
	---сделан джойн заместо подзапроса
	AS TotalSummForPickedItems
FROM Sales.Invoices
JOIN Application.People
	ON Invoices.SalespersonPersonID = People.PersonID
JOIN SalesTotals
	ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC;

--Приложите план запроса и его анализ, а также ход ваших рассуждений по поводу оптимизации.
--Можно двигаться как в сторону улучшения читабельности запроса (что уже было в материале лекций), так и в сторону упрощения плана\ускорения.