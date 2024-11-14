-- Crear el primer login y usuario
CREATE LOGIN LoginDeposito WITH PASSWORD = 'deposito';
USE TiendaElectronica;
CREATE USER EmpleadoDeposito FOR LOGIN LoginDeposito;

-- Crear el segundo login y usuario
CREATE LOGIN LoginCaja WITH PASSWORD = 'caja';
USE TiendaElectronica;
CREATE USER EmpleadoCaja FOR LOGIN LoginCaja;

-- El empleado de deposito puede insertar, seleccionar, modificar y borrar de la tabla Stock
GRANT SELECT ON dbo.Stock TO EmpleadoDeposito; 
GRANT INSERT ON dbo.Stock TO EmpleadoDeposito; 
GRANT UPDATE ON dbo.Stock TO EmpleadoDeposito; 
GRANT DELETE ON dbo.Stock TO EmpleadoDeposito; 

-- El empleado de caja puede insertar, seleccionar, modificar y borrar de la tabla Compras y Detalles_Compras
GRANT SELECT ON dbo.Compras TO EmpleadoCaja; 
GRANT INSERT ON dbo.Compras TO EmpleadoCaja; 
GRANT UPDATE ON dbo.Compras TO EmpleadoCaja;  
GRANT DELETE ON dbo.Compras TO EmpleadoCaja; 

GRANT SELECT ON dbo.Detalle_Compras TO EmpleadoCaja; 
GRANT INSERT ON dbo.Detalle_Compras TO EmpleadoCaja; 
GRANT UPDATE ON dbo.Detalle_Compras TO EmpleadoCaja;  
GRANT DELETE ON dbo.Detalle_Compras TO EmpleadoCaja;
