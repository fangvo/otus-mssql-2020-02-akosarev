--1. Все товары, в которых в название есть пометка urgent или название начинается с Animal
SELECT
  StockItemID,
  StockItemName
FROM Warehouse.StockItems
WHERE
  StockItemName LIKE '%urgent%'
  OR StockItemName LIKE 'Animal%';

--2. Поставщиков, у которых не было сделано ни одного заказа (потом покажем как это делать через подзапрос, сейчас сделайте через JOIN)
SELECT
  Suppliers.SupplierID,
  SupplierName
FROM Purchasing.Suppliers
LEFT OUTER JOIN Purchasing.PurchaseOrders ON Suppliers.SupplierID = PurchaseOrders.SupplierID
WHERE
  PurchaseOrderID IS NULL;

--3. Продажи с названием месяца, в котором была продажа, номером квартала, к которому относится продажа,
--включите также к какой трети года относится дата - каждая треть по 4 месяца, дата забора заказа должна быть задана,
--с ценой товара более 100$ либо количество единиц товара более 20. 
--Добавьте вариант этого запроса с постраничной выборкой пропустив первую 1000 и отобразив следующие 100 записей.
--Соритровка должна быть по номеру квартала, трети года, дате продажи.

SELECT
  DISTINCT Orders.OrderId,
  OrderDate,
  DATENAME(m, OrderDate) AS [Month],
  DATEPART(q, OrderDate) AS Quater,CASE
    WHEN DATEPART(m, OrderDate) BETWEEN 1
    AND 4 THEN 1
    WHEN DATEPART(m, OrderDate) BETWEEN 5
    AND 8 THEN 2
    ELSE 3
  END AS ThirdOfYear
FROM Sales.Orders
JOIN Sales.OrderLines ON Orders.OrderID = OrderLines.OrderID
WHERE
  UnitPrice > 100
  OR Quantity > 20;

SELECT
  DISTINCT Orders.OrderId,
  OrderDate,
  DATENAME(m, OrderDate) AS [Month],
  DATEPART(q, OrderDate) AS Quater,CASE
    WHEN DATEPART(m, OrderDate) BETWEEN 1
    AND 4 THEN 1
    WHEN DATEPART(m, OrderDate) BETWEEN 5
    AND 8 THEN 2
    ELSE 3
  END AS ThirdOfYear
FROM Sales.Orders
JOIN Sales.OrderLines ON Orders.OrderID = OrderLines.OrderID
WHERE
  UnitPrice > 100
  OR Quantity > 20
ORDER BY
  Quater,
  ThirdOfYear,
  OrderDate OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY;

--4. Заказы поставщикам, которые были исполнены за 2014й год с доставкой Road Freight или Post, добавьте название поставщика, имя контактного лица принимавшего заказ

SELECT
  PurchaseOrderID,
  SupplierName,
  FullName
FROM Purchasing.PurchaseOrders
JOIN Purchasing.Suppliers ON PurchaseOrders.SupplierID = Suppliers.SupplierID
JOIN Application.People ON PurchaseOrders.ContactPersonID = People.PersonID
WHERE
  PurchaseOrders.DeliveryMethodID IN (1, 7)
  AND PurchaseOrders.IsOrderFinalized = 1
  AND DATEPART(yyyy, PurchaseOrders.ExpectedDeliveryDate) = 2014;

--5. 10 последних по дате продаж с именем клиента и именем сотрудника, который оформил заказ.

SELECT
  TOP 10 OrderID,
  CustomerName,
  FullName
FROM Sales.Orders
JOIN Sales.Customers ON Orders.CustomerID = Customers.CustomerID
JOIN Application.People ON Orders.SalespersonPersonID = People.PersonID
ORDER BY
  OrderDate DESC;

--6. Все ид и имена клиентов и их контактные телефоны, которые покупали товар Chocolate frogs 250g

SELECT
  DISTINCT Customers.CustomerID,
  CustomerName,
  PhoneNumber
FROM Sales.OrderLines
JOIN Sales.Orders ON OrderLines.OrderID = Orders.OrderID
JOIN Sales.Customers ON Orders.CustomerID = Customers.CustomerID
WHERE
  StockItemID = (
    SELECT
      StockItemID
    FROM Warehouse.StockItems
    WHERE
      StockItemName = 'Chocolate frogs 250g'
  );
