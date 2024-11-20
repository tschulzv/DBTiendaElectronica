USE DBTienda;

-- PRUEBAS DE VISTAS -------------------------------------
-- FACTURAS VENCIDAS 
SELECT * FROM view_facturas_vencidas;

-- STOCK DE PRODUCTOS
-- Stock por depósito
SELECT * FROM view_stock_productos;
-- Stock total
SELECT * FROM view_stock_total_productos;