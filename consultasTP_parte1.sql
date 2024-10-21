use TiendaElectronica;

/*
Monto del importe total de compras realizadas en un rango de fechas (entre dos fechas), 
desplegar los atributos: fecha, c�digo y nombre de dep�sito, importe total de compras para esa fecha y dep�sito. (1).
*/

SELECT 
    c.fecha_compra AS Fecha,
    d.id_deposito AS Codigo_Deposito,
    d.nombre AS Deposito,
    SUM(C.total_compra) AS Importe_Total_Compras
FROM Compras c
INNER JOIN Depositos d ON c.id_deposito = d.id_deposito
WHERE c.fecha_compra BETWEEN '2024-01-01' AND '2024-03-31'
GROUP BY 
    c.fecha_compra, d.id_deposito, D.nombre
ORDER BY 
    c.fecha_compra, d.id_deposito;


/* Productos comprados a proveedores, el criterio de recuperaci�n es por rango de proveedores y rango de fechas, 
desplegar los siguientes atributos: C�digo y nombre del Proveedor, c�digo
*/

SELECT 
    P.id_proveedor AS Codigo_Proveedor,
    P.nombre AS Nombre_Proveedor,
    Pr.id_producto AS Codigo_Producto,
    Pr.descripcion AS Descripcion_Producto,
    MAX(C.fecha_compra) AS Ultima_Fecha_Compra,
    Pr.ultimo_costo_unitario AS Ultimo_Costo_Unitario
FROM Compras C
INNER JOIN Proveedores P ON C.id_proveedor = P.id_proveedor
INNER JOIN Detalle_Compras DC ON C.id_compra = DC.id_compra
INNER JOIN Productos Pr ON DC.id_producto = Pr.id_producto
WHERE P.id_proveedor BETWEEN 1 AND 5 AND C.fecha_compra BETWEEN '2024-01-01' AND '2024-03-31'
GROUP BY 
    P.id_proveedor, P.nombre, Pr.id_producto, Pr.descripcion, Pr.ultimo_costo_unitario
ORDER BY 
    P.id_proveedor, Pr.id_producto;

/* Productos comprados a m�s de un proveedor por rango de proveedores, desplegar
los atributos: C�digo y descripci�n del Producto, c�digo y nombre del proveedor. */

SELECT 
	Pr.id_producto as Codigo_Producto,
	Pr.descripcion as Descripcion_Producto,
	P.id_proveedor AS Codigo_Proveedor,
    P.nombre AS Nombre_Proveedor
FROM (SELECT d.id_producto
	FROM Compras c2
	INNER JOIN Detalle_Compras d ON d.id_compra = c2.id_compra
	GROUP BY d.id_producto
	HAVING COUNT(c2.id_proveedor) > 1) AS Prod_mult_proveedores
INNER JOIN Detalle_Compras DC ON Prod_mult_proveedores.id_producto = DC.id_producto
INNER JOIN Compras C ON DC.id_compra = C.id_compra
INNER JOIN Proveedores P ON C.id_proveedor = P.id_proveedor
INNER JOIN Productos Pr ON DC.id_producto = Pr.id_producto
WHERE C.id_proveedor BETWEEN 1 AND 3;

/*- Informe de facturas de compra pendientes de pago, desplegar los atributos: Factura,
fecha, c�digo y nombre del proveedor, total de la factura y saldo de la factura.*/
SELECT c.id_compra AS "Factura", c.fecha_compra AS "Fecha", pr.id_proveedor AS "Codigo", pr.nombre AS "Proveedor",  
	c.total_compra AS "Total", c.saldo_compra AS "Saldo"
FROM Compras c
JOIN Proveedores pr ON c.id_proveedor = pr.id_proveedor
WHERE c.saldo_compra > 0
ORDER BY c.fecha_compra, pr.nombre;

/* Ranking de productos (Productos m�s comprados, por cantidad de productos)*/
SELECT p.id_producto AS "C�digo del Producto", p.descripcion AS "Descripci�n del Producto", SUM(dc.cantidad) AS "Cantidad Comprada"
FROM Productos p
JOIN Detalle_Compras dc ON p.id_producto = dc.id_producto
GROUP BY p.id_producto, p.descripcion
ORDER BY SUM(dc.cantidad) DESC;

/*Ranking de proveedores (Proveedores a los que m�s se les compra, por monto de facturaci�n)*/
SELECT p.id_proveedor AS "C�digo del Proveedor", p.nombre AS "Nombre del Proveedor", SUM(c.total_compra) AS "Monto Total de Facturaci�n"
FROM Proveedores p
JOIN Compras c ON p.id_proveedor = c.id_proveedor
GROUP BY p.id_proveedor, p.nombre
ORDER BY SUM(c.total_compra) DESC;