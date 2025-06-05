-- Aclaracion: Lo que no esta comentado en el codigo, esta en el archivo Estrategia.pdf

USE GD1C2025 -- Asegurarse de usar la base de datos correcta

CREATE TABLE DATA_DEALERS.BI_Dimension_Tiempo (
    Tiempo_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Anio SMALLINT NOT NULL,
    Cuatrimestre TINYINT NOT NULL,
    Mes TINYINT NOT NULL
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Ubicacion (
    Ubicacion_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Provincia NVARCHAR(255),
    Localidad NVARCHAR(255)
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Rango_Etario_Clientes (
    Rango_Etario_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Edad_Minima TINYINT,
    Edad_Maxima TINYINT
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Turno_Ventas (
    Turno_Ventas_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Horario_Minimo TINYINT, 
    Horario_Maximo TINYINT  
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Tipo_Material (
    Tipo_Material_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Tela NVARCHAR(255),
    Madera NVARCHAR(255),
    Relleno NVARCHAR(255)
)

CREATE TABLE DATA_DEALERS.DATA_DEALERS.BI_Dimension_Modelo_Sillon (
    Modelo_Sillon_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Nombre_Modelo NVARCHAR(255)
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Estado_Pedido (
    Estado_Pedido_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Estado_Pedido NVARCHAR(255)
)

CREATE TABLE DATA_DEALERS.BI_Hechos_Ventas (
    Rango_Etario_Id BIGINT REFERENCES BI_Dimension_Rango_Etario_Clientes(Rango_Etario_Id),
    Ubicacion_Id BIGINT REFERENCES BI_Dimension_Ubicacion(Ubicacion_Id),
    Tiempo_Id BIGINT REFERENCES BI_Dimension_Tiempo(Tiempo_Id),
    Estado_Pedido_Id BIGINT REFERENCES BI_Dimension_Estado_Pedido(Estado_Pedido_Id),
    Modelo_Sillon_Id BIGINT REFERENCES BI_Dimension_Modelo_Sillon(Modelo_Sillon_Id),
    Tipo_Material_Id BIGINT REFERENCES BI_Dimension_Tipo_Material(Tipo_Material_Id),
    Turno_Ventas_Id BIGINT REFERENCES BI_Dimension_Turno_Ventas(Turno_Ventas_Id),

    Total_Ingresos DECIMAL(38,2),
    Total_Egresos DECIMAL(38,2),
    Cantidad_Facturas BIGINT,
    Cantidad_Pedidos BIGINT,
    Promedio_Tiempo_Fabricacion DECIMAL(6,2),
    Cantidad_Compras BIGINT,
    Cantidad_Envios BIGINT,
    Cantidad_Envios_Cumplidos BIGINT,
    Total_Costo_Envios BIGINT,

    PRIMARY KEY (
        Rango_Etario_Id,
        Ubicacion_Id,
        Tiempo_Id,
        Estado_Pedido_Id,
        Modelo_Sillon_Id,
        Tipo_Material_Id,
        Turno_Ventas_Id
    ),
)
/*
SUM(Total_Ingresos) - SUM(Total_Egresos)
GROUP BY Mes, Anio, Sucursal
*/