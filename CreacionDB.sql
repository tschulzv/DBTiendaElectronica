CREATE DATABASE TiendaElectronica;
USE TiendaElectronica;

-- creación de tablas
CREATE TABLE Medios_de_Pago (
  id_medio_de_pago INT not null,
  descripcion VARCHAR(50) not null,
  PRIMARY KEY (id_medio_de_pago)
);

CREATE TABLE Depositos (
  id_deposito INT not null,
  nombre VARCHAR(50) not null,
  PRIMARY KEY (id_deposito)
);

CREATE TABLE Proveedores (
  id_proveedor INT not null,
  nombre VARCHAR(50) not null,
  direccion VARCHAR(150) not null,
  telefono VARCHAR(15) not null,
  correo_electronico VARCHAR(100) null,
  linea_credito NUMERIC(12) not null,
  PRIMARY KEY (id_proveedor)
);

CREATE TABLE Pagos (
  id_pago INT not null,
  id_proveedor INT not null,
  fecha DATE not null,
  importe_total NUMERIC(12) not null,
  PRIMARY KEY (id_pago),
  FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor)
);

CREATE TABLE Detalles_Forma_Pago (
  id_detalle_forma_pago INT not null,
  id_pago INT not null,
  id_medio_de_pago INT not null,
  monto NUMERIC(12) not null,
  PRIMARY KEY (id_detalle_forma_pago),
  FOREIGN KEY (id_medio_de_pago) REFERENCES Medios_de_Pago(id_medio_de_pago),
  FOREIGN KEY (id_pago) REFERENCES Pagos(id_pago)
);

CREATE TABLE Empleados (
  id_empleado INT not null,
  nombre VARCHAR(100) not null,
  PRIMARY KEY (id_empleado)
);

CREATE TABLE Transferencias_Productos (
  id_transferencia INT not null,
  fecha DATE not null,
  id_deposito_origen INT not null,
  id_deposito_destino INT not null,
  id_encargado INT not null,
  id_autorizante INT not null,
  PRIMARY KEY (id_transferencia),
  FOREIGN KEY (id_deposito_origen) REFERENCES Depositos(id_deposito),
  FOREIGN KEY (id_deposito_destino) REFERENCES Depositos(id_deposito),
  FOREIGN KEY (id_encargado) REFERENCES Empleados(id_empleado),
  FOREIGN KEY (id_autorizante) REFERENCES Empleados(id_empleado)
);

CREATE TABLE Marcas (
  id_marca INT not null,
  nombre VARCHAR(50) not null,
  PRIMARY KEY (id_marca)
);

CREATE TABLE Categorias (
  id_categoria INT not null,
  nombre VARCHAR(50) not null,
  PRIMARY KEY (id_categoria)
);

CREATE TABLE Productos (
  id_producto INT not null,
  descripcion VARCHAR(150) not null,
  id_marca INT not null,
  id_categoria INT not null,
  ultimo_costo_unitario NUMERIC(9) not null,
  paga_iva BIT not null,
  porcentaje_iva NUMERIC(5) null,
  PRIMARY KEY (id_producto),
  FOREIGN KEY (id_marca) REFERENCES Marcas(id_marca),
  FOREIGN KEY (id_categoria) REFERENCES Categorias(id_categoria)
);

CREATE TABLE Detalles_Transferencia (
  id_detalle_transferencia INT not null,
  id_transferencia INT not null,
  id_producto INT not null,
  cantidad NUMERIC(6) not null,
  PRIMARY KEY (id_detalle_transferencia),
  FOREIGN KEY (id_transferencia) REFERENCES Transferencias_Productos(id_transferencia),
  FOREIGN KEY (id_producto) REFERENCES Productos(id_producto)
);

CREATE TABLE Compras (
  id_compra INT not null,
  id_proveedor INT not null,
  fecha_compra DATE not null,
  condicion_compra VARCHAR(10) not null,
  fecha_vencimiento DATE not null,
  id_deposito INT not null,
  total_compra NUMERIC(12) not null,
  saldo_compra NUMERIC(12) not null,
  PRIMARY KEY (id_compra),
  FOREIGN KEY (id_deposito) REFERENCES Depositos(id_deposito),
  FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor)
);

CREATE TABLE Detalle_Compras (
  id_detalle INT not null,
  id_compra INT not null,
  id_producto INT not null,
  cantidad NUMERIC(6) not null,
  costo_unitario NUMERIC(9) not null,
  porcentaje_iva NUMERIC(5) not null,
  PRIMARY KEY (id_detalle),
  FOREIGN KEY (id_compra) REFERENCES Compras(id_compra),
  FOREIGN KEY (id_producto) REFERENCES Productos(id_producto)
);

CREATE TABLE Stock (
  id_stock INT not null,
  id_producto INT not null,
  id_deposito INT not null,
  cantidad NUMERIC(6) not null,
  ultima_actualizacion DATE not null,
  PRIMARY KEY (id_stock),
  FOREIGN KEY (id_producto) REFERENCES Productos(id_producto),
  FOREIGN KEY (id_deposito) REFERENCES Depositos(id_deposito)
);

CREATE TABLE Detalles_Pagos (
  id_detalle_pago INT not null,
  id_pago INT not null,
  id_compra INT not null,
  importe_pagado NUMERIC(12) not null,
  PRIMARY KEY (id_detalle_pago),
  FOREIGN KEY (id_pago) REFERENCES Pagos(id_pago),
  FOREIGN KEY (id_compra) REFERENCES Compras(id_compra)
);

-- Insertar datos en Medios_de_Pago
INSERT INTO Medios_de_Pago (id_medio_de_pago, descripcion) VALUES
(1, 'Efectivo'),
(2, 'Transferencia Bancaria'),
(3, 'Tarjeta de Crédito'),
(4, 'Tarjeta de Débito');

-- Insertar datos en Depositos
INSERT INTO Depositos (id_deposito, nombre) VALUES
(1, 'Depósito Central'),
(2, 'Depósito Secundario');

-- Insertar datos en Proveedores
INSERT INTO Proveedores (id_proveedor, nombre, direccion, telefono, correo_electronico, linea_credito) VALUES
(1, 'Proveedora Tecnológica S.A.', 'Av. Mariscal López 1234', '+595991123456', 'contacto@proveedoratec.com', 50000000),
(2, 'Suministros Informáticos SRL', 'Calle Palma 567', '+595991654321', 'ventas@suministros.com', 75000000),
(3, 'Computadoras del Sur', 'Av. San Martín 890', '+595991987654', 'info@computadorasdelsur.com', 100000000),
(4, 'Tecnología Guaraní', 'Ruta Transchaco Km 12', '+595992345678', 'soporte@tecguarani.com', 60000000),
(5, 'Distribuidora Bytes', 'Av. España 456', '+595991112233', 'ventas@bytes.com', 85000000),
(6, 'Hardware Plus', 'Calle Artigas 234', '+595992334455', 'info@hardwareplus.com', 45000000),
(7, 'Periféricos del Este', 'Av. Pioneros 678', '+595991223344', 'ventas@perifericoseste.com', 78000000),
(8, 'Electrónica Integral', 'Ruta Luque-San Bernardino', '+595992445566', 'contacto@electronicaintegral.com', 50000000),
(9, 'Innovaciones Informáticas', 'Av. Molas López 234', '+595991998877', 'soporte@innovatics.com', 60000000),
(10, 'Tecnología Avanzada PY', 'Calle Constitución 100', '+595992556677', 'ventas@tecnologiapy.com', 72000000);

-- Insertar datos en Empleados
INSERT INTO Empleados (id_empleado, nombre) VALUES
(1, 'Carlos González'),
(2, 'Laura Fernández'),
(3, 'Mario Cáceres'),
(4, 'Ana Pereira'),
(5, 'Jorge Ramírez'),
(6, 'Sofía López'),
(7, 'Martín Duarte'),
(8, 'Fernando Franco'),
(9, 'Gabriela Villalba'),
(10, 'Rodrigo Benítez');

-- Insertar datos en Marcas
INSERT INTO Marcas (id_marca, nombre) VALUES
(1, 'HP'),
(2, 'Dell'),
(3, 'Lenovo'),
(4, 'Asus'),
(5, 'Acer'),
(6, 'MSI'),
(7, 'Apple'),
(8, 'Toshiba'),
(9, 'Samsung'),
(10, 'Huawei');

-- Insertar datos en Categorias
INSERT INTO Categorias (id_categoria, nombre) VALUES
(1, 'Laptops'),
(2, 'Monitores'),
(3, 'Teclados'),
(4, 'Mouses'),
(5, 'Impresoras'),
(6, 'Discos Duros'),
(7, 'Memorias RAM'),
(8, 'Tarjetas Gráficas'),
(9, 'Procesadores'),
(10, 'Fuentes de Alimentación');

-- Insertar datos en Productos
INSERT INTO Productos (id_producto, descripcion, id_marca, id_categoria, ultimo_costo_unitario, paga_iva, porcentaje_iva) VALUES
(1, 'Laptop HP Pavilion 15', 1, 1, 4500000, 1, 10),
(2, 'Monitor Dell 24 pulgadas', 2, 2, 1200000, 1, 10),
(3, 'Teclado Mecánico Lenovo', 3, 3, 350000, 1, 5),
(4, 'Mouse Óptico Asus', 4, 4, 150000, 1, 5),
(5, 'Impresora Multifunción HP', 1, 5, 950000, 1, 10),
(6, 'Disco Duro Externo 1TB Toshiba', 8, 6, 400000, 1, 5),
(7, 'Memoria RAM DDR4 16GB Corsair', 7, 7, 750000, 1, 5),
(8, 'Tarjeta Gráfica RTX 3060', 6, 8, 6000000, 1, 10),
(9, 'Procesador Intel i7 12th Gen', 9, 9, 2000000, 1, 10),
(10, 'Fuente de Alimentación 700W Corsair', 7, 10, 350000, 1, 5);

-- Insertar datos en Compras
INSERT INTO Compras (id_compra, id_proveedor, fecha_compra, condicion_compra, fecha_vencimiento, id_deposito, total_compra, saldo_compra) VALUES
(1, 1, '2024-01-20', 'Crédito', '2024-02-20', 1, 22500000, 2500000), 
(2, 2, '2024-01-20', 'Contado', '2024-01-20', 1, 3600000, 0),
(3, 3, '2024-02-15', 'Crédito', '2024-03-15', 1, 3500000, 0), 
(4, 4, '2024-03-01', 'Contado', '2024-03-01', 1, 2250000, 0), 
(5, 5, '2024-03-01', 'Crédito', '2024-04-20', 1, 1900000, 900000), 
(6, 2, '2024-03-22', 'Crédito', '2024-04-22', 2, 22500000, 10000000), -- nuevos datos
(7, 3, '2024-03-22', 'Contado', '2024-03-22', 1, 3600000, 0),
(8, 4, '2024-03-30', 'Contado', '2024-03-30', 2, 1750000, 0);

-- Insertar datos en Detalles_Compra
INSERT INTO Detalle_Compras (id_detalle, id_compra, id_producto, costo_unitario, cantidad, porcentaje_iva) VALUES
(1, 1, 1, 4500000, 5, 10),
(2, 2, 2, 1200000, 3, 10),
(3, 3, 3, 350000, 10, 5),
(4, 4, 4, 150000, 15, 5),
(5, 5, 5, 950000, 2, 10),
(6, 6, 1, 4500000, 5, 10), -- nuevos datos
(7, 7, 2, 1200000, 3, 10),
(8, 8, 3, 350000, 5, 5);

-- Insertar datos en Pagos
INSERT INTO Pagos (id_pago, id_proveedor, fecha, importe_total) VALUES
(1, 1, '2024-01-20', 10000000), -- primer pago compra 1
(2, 2, '2024-01-20', 3600000),
(3, 1, '2024-01-25', 10000000), -- segundo pago de la compra 1
(4, 3, '2024-02-20', 3500000), -- cancelacion compra 3
(5, 4, '2024-03-01', 2250000), 
(6, 5, '2024-03-05', 1000000), -- primer pago compra 5
(7, 2, '2024-03-25', 12500000), -- primer pago compra 6
(8, 3, '2024-03-22', 3600000),  
(9, 4, '2024-03-30', 1750000);

INSERT INTO Detalles_Pagos(id_detalle_pago, id_pago, id_compra, importe_pagado) VALUES
(1, 1, 1, 10000000),
(2, 2, 2, 3600000),
(3, 3, 1, 10000000), -- segundo pago compra 1
(4, 4, 3, 3500000), 
(5, 5, 4, 2250000), 
(6, 6, 5, 1000000),
(7, 7, 6, 12500000), 
(8, 8, 7, 3600000),
(9, 9, 8, 1750000);

-- Insertar datos en Detalles_Forma_Pago
INSERT INTO Detalles_Forma_Pago (id_detalle_forma_pago, id_pago, id_medio_de_pago, monto) VALUES
(1, 1, 1, 10000000),
(2, 2, 2, 3600000),
(3, 3, 3, 10000000),
(4, 4, 4, 3500000),
(5, 5, 1, 2250000), 
(6, 6, 2, 1000000),
(7, 7, 3, 12500000), 
(8, 8, 4, 3600000),
(9, 9, 1, 1750000);

-- Insertar datos en Stock
INSERT INTO Stock (id_stock, id_producto, id_deposito, cantidad, ultima_actualizacion) VALUES
(1, 1, 1, 5, '2024-01-31'),
(2, 2, 2, 3, '2024-03-31'), 
(3, 3, 1, 5, '2024-03-31'), 
(4, 4, 2, 15, '2024-03-01'), 
(5, 5, 1, 2, '2024-03-01'),
(6, 1, 2, 5, '2024-01-31'),
(7, 2, 1, 3, '2024-03-31'),
(8, 3, 2, 10, '2024-03-31'); 

-- Insertar datos en Transferencias_Productos
INSERT INTO Transferencias_Productos (id_transferencia, fecha, id_deposito_origen, id_deposito_destino, id_encargado, id_autorizante) VALUES
(1, '2024-01-31', 1, 2, 1, 2),
(2, '2024-03-31', 2, 1, 3, 4),
(3, '2024-03-31', 1, 2, 5, 6);

-- Insertar datos en Detalles_Transferencia
INSERT INTO Detalles_Transferencia (id_detalle_transferencia, id_transferencia, id_producto, cantidad) VALUES
(1, 1, 1, 5),  -- 5 Laptops HP transferidas del Depósito Central al Secundario
(2, 2, 2, 3),  -- 3 Monitores Dell transferidos del Depósito Secundario al Central
(3, 3, 3, 10); -- 10 Teclados Lenovo transferidos del Depósito Central al Secundario
