-- Aclaracion: Lo que no esta comentado en el codigo, esta en el archivo Estrategia.pdf

USE GD1C2025 -- Asegurarse de usar la base de datos correcta

----------------------------- CREACION DE ESTRUCTURAS -----------------------------

--------- TABLAS ---------

-- Dimensiones

CREATE TABLE DATA_DEALERS.BI_Dimension_Tiempo (
    Tiempo_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Anio SMALLINT,
    Cuatrimestre TINYINT,
    Mes TINYINT
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Ubicacion (
    Ubicacion_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Provincia NVARCHAR(255),
    Localidad NVARCHAR(255)
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Rango_Etario_Clientes (
    Rango_Etario_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Edad_Minima TINYINT, -- Justificacion
    Edad_Maxima TINYINT
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Turno_Ventas (
    Turno_Ventas_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Horario_Minimo TINYINT,
    Horario_Maximo TINYINT
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Tipo_Material (
    Tipo_Material_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Tipo_Material NVARCHAR(255)
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Modelo_Sillon (
    Modelo_Sillon_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Nombre_Modelo NVARCHAR(255)
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Estado_Pedido (
    Estado_Pedido_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Estado_Pedido NVARCHAR(255)
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Sucursal (
    Sucursal_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Sucursal_NroSucursal BIGINT
)

-- Hechos

CREATE TABLE DATA_DEALERS.BI_Hechos_Ventas (
    Detalle_Factura_Numero BIGINT,
    Factura_Numero BIGINT,
    Modelo_Sillon_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Modelo_Sillon,
    Rango_Etario_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Rango_Etario_Clientes,
    Tiempo_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Ubicacion_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Ubicacion,
    Sucursal_Id BIGINT NOT NULL REFERENCES  DATA_DEALERS.BI_Dimension_Sucursal,
    Detalle_Subtotal DECIMAL(38,2) NOT NULL,
    Detalle_Cantidad BIGINT NOT NULL,
    Detalle_Tiempo_Fabricacion DECIMAL(6,2) NOT NULL,
    PRIMARY KEY (Detalle_Factura_Numero, Factura_Numero)
)

CREATE TABLE DATA_DEALERS.BI_Hechos_Compras (
    Detalle_Compra_Codigo BIGINT,
    Compra_Numero BIGINT,
    Tiempo_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Sucursal_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Sucursal,
    Tipo_Material_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Tipo_Material,
    Detalle_Subtotal DECIMAL(38,2) NOT NULL,
    PRIMARY KEY (Detalle_Compra_Codigo, Compra_Numero)
)

CREATE TABLE DATA_DEALERS.BI_Hechos_Pedidos (
    Pedido_Numero DECIMAL(18,0) PRIMARY KEY,
    Tiempo_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Sucursal_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Sucursal,
    Estado_Pedido_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Estado_Pedido,
    Turno_Ventas_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Turno_Ventas
)

CREATE TABLE DATA_DEALERS.BI_Hechos_Envios (
    Envio_Numero DECIMAL(18,0) PRIMARY KEY,
    Tiempo_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Ubicacion_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Ubicacion,
    Envio_Fecha_Programada DATETIME2(0) NOT NULL,
    Envio_Fecha_Entrega DATETIME2(0),
    Envio_Total DECIMAL(18,2) NOT NULL
)

--------- VISTAS ---------

-- 1. Ganancias: Total de ingresos (facturación) - total de egresos (compras), por
--     cada mes, por cada sucursal.
--     [VENTAS, COMPRAS]
/*
CREATE VIEW DATA_DEALERS.VW_Ganancias_Mensuales AS
SELECT 
    t.Anio,
    t.Cuatrimestre,
    t.Mes,
    s.Sucursal_NroSucursal,
    v.Total_Ingresos - c.Total_Egresos AS Ganancias
FROM DATA_DEALERS.BI_Hechos_Ventas v
    LEFT JOIN
        DATA_DEALERS.BI_Hechos_Compras c ON v.Tiempo_Id = c.Tiempo_Id AND v.Sucursal_Id = c.Sucursal_Id
    LEFT JOIN
        DATA_DEALERS.BI_Dimension_Tiempo t ON v.Tiempo_Id = t.Tiempo_Id
    LEFT JOIN
        DATA_DEALERS.BI_Dimension_Sucursal s ON v.Sucursal_Id = s.Sucursal_Id

-- 2.Factura promedio mensual. Valor promedio de las facturas (en $) según la
--     provincia de la sucursal para cada cuatrimestre de cada Anio. Se calcula en
--     función de la sumatoria del importe de las facturas sobre el total de las mismas
--     durante dicho período.
--     [VENTAS]

CREATE VIEW DATA_DEALERS.VW_Factura_Promedio_Mensual AS
SELECT 
    t.Anio,
    t.Cuatrimestre,
    t.Mes,
    u.Provincia,
    v.Total_Ingresos / v.Cantidad_Facturas AS Factura_Promedio
FROM DATA_DEALERS.BI_Hechos_Ventas v
    JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON v.Tiempo_Id = t.Tiempo_Id
    JOIN DATA_DEALERS.BI_Dimension_Ubicacion u ON v.Ubicacion_Id = u.Ubicacion_Id
   
-- 3. Rendimiento de modelos. Los 3 modelos con mayores ventas para cada
--     cuatrimestre de cada Anio según la localidad de la sucursal y rango etario de los
--     clientes.
--     [VENTAS_DETALLE]

-- No anda por algun motivo xd

CREATE VIEW DATA_DEALERS.VW_Top3_Modelos_Cuatrimestral AS
SELECT 
    t.Anio,
    t.Cuatrimestre,
    u.Localidad,
    r.Rango_Etario_Id,
    m.Sillon_Modelo,
    SUM(vd.Detalle_Cantidad) AS Total_Vendido
FROM DATA_DEALERS.BI_Hechos_Ventas_Detalles vd
    JOIN DATA_DEALERS.BI_Dimension_Modelo_Sillon m ON vd.Modelo_Sillon_Id = m.Modelo_Sillon_Id
    JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON vd.Tiempo_Id = t.Tiempo_Id
    JOIN DATA_DEALERS.BI_Dimension_Ubicacion u ON vd.Ubicacion_Id = u.Ubicacion_Id
    JOIN DATA_DEALERS.BI_Dimension_Rango_Etario_Clientes r ON vd.Rango_Etario_Id = r.Rango_Etario_Id
GROUP BY 
    t.Anio, 
    t.Cuatrimestre, 
    u.Localidad, 
    r.Rango_Etario_Id, 
    m.Sillon_Modelo
HAVING (
    SELECT COUNT(DISTINCT SUM(vd2.Detalle_Cantidad))
    FROM DATA_DEALERS.BI_Hechos_Ventas_Detalles vd2
        JOIN DATA_DEALERS.BI_Dimension_Modelo_Sillon m2 ON vd2.Modelo_Sillon_Id = m2.Modelo_Sillon_Id
        JOIN DATA_DEALERS.BI_Dimension_Tiempo t2 ON vd2.Tiempo_Id = t2.Tiempo_Id
        JOIN DATA_DEALERS.BI_Dimension_Ubicacion u2 ON vd2.Ubicacion_Id = u2.Ubicacion_Id
        JOIN DATA_DEALERS.BI_Dimension_Rango_Etario_Clientes r2 ON vd2.Rango_Etario_Id = r2.Rango_Etario_Id
    WHERE 
        t2.Anio = t.Anio AND
        t2.Cuatrimestre = t.Cuatrimestre AND
        u2.Localidad = u.Localidad AND
        r2.Rango_Etario_Id = r.Rango_Etario_Id AND
        (SUM(vd2.Detalle_Cantidad) > SUM(vd.Detalle_Cantidad) OR (SUM(vd2.Detalle_Cantidad) = SUM(vd.Detalle_Cantidad) AND m2.Sillon_Modelo < m.Sillon_Modelo)) -- Justificacion (Desempata por numero de modelo, pq si no podria haber mas de 3 en el top 3)
    GROUP BY m2.Sillon_Modelo
) < 3

-- 4. Volumen de pedidos. Cantidad de pedidos registrados por turno, por sucursal
--     según el mes de cada Anio. 
--     [PEDIDOS]

CREATE VIEW DATA_DEALERS.VW_Volumen_Pedidos AS
SELECT 
    t.Anio,
    t.Mes,
    p.Sucursal_Id,
    p.Turno_Ventas_Id,
    COUNT(DISTINCT p.Pedido_Numero) AS Cantidad_Pedidos
FROM DATA_DEALERS.BI_Hechos_Pedidos p
    JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON p.Tiempo_Id = t.Tiempo_Id
GROUP BY 
    t.Anio, 
    t.Mes, 
    p.Sucursal_Id, 
    p.Turno_Ventas_Id;

-- 5. Conversión de pedidos. Porcentaje de pedidos según estado, por cuatrimestre y
--     sucursal.
--     [PEDIDOS]

CREATE VIEW DATA_DEALERS.VW_Conversion_Pedidos AS
SELECT 
    t.Anio,
    t.Cuatrimestre,
    p.Sucursal_Id,
    e.Estado_Pedido,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY t.Anio, t.Cuatrimestre, p.Sucursal_Id) AS Porcentaje
FROM DATA_DEALERS.BI_Hechos_Pedidos p
    JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON p.Tiempo_Id = t.Tiempo_Id
    JOIN DATA_DEALERS.BI_Dimension_Estado_Pedido e ON p.Estado_Pedido_Id = e.Estado_Pedido_Id
GROUP BY 
    t.Anio, 
    t.Cuatrimestre, 
    p.Sucursal_Id, 
    e.Estado_Pedido;

-- 6. Tiempo promedio de fabricación: Tiempo promedio que tarda cada sucursal
--     entre que se registra un pedido y registra la factura para el mismo. Por
--     cuatrimestre.
--     [VENTAS]

CREATE VIEW DATA_DEALERS.VW_Tiempo_Promedio_Fabricacion AS
SELECT 
    t.Anio,
    t.Cuatrimestre,
    h.Sucursal_Id,
    AVG(DATEDIFF(DAY, p.Tiempo_Id, h.Tiempo_Id)) AS Promedio_Dias
FROM DATA_DEALERS.BI_Hechos_Ventas h
    JOIN DATA_DEALERS.BI_Hechos_Pedidos p ON h.Cliente_Id = p.Sucursal_Id AND h.Rango_Etario_Id = p.Turno_Ventas_Id
    JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON h.Tiempo_Id = t.Tiempo_Id
GROUP BY 
    t.Anio, 
    t.Cuatrimestre, 
    h.Sucursal_Id;

-- 7. Promedio de Compras: importe promedio de compras por mes.
--     [COMPRAS]

CREATE VIEW DATA_DEALERS.VW_Promedio_Compras_Mensual AS
SELECT 
    t.Anio,
    t.Mes,
    AVG(c.Detalle_Subtotal) AS Promedio_Compra
FROM DATA_DEALERS.BI_Hechos_Compras c
    JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON c.Tiempo_Id = t.Tiempo_Id
GROUP BY 
    t.Anio, 
    t.Mes;

-- 8. Compras por Tipo de Material. Importe total gastado por tipo de material,
--     sucursal y cuatrimestre.
--     [COMPRAS]

CREATE VIEW DATA_DEALERS.VW_Compras_Por_Material AS
SELECT 
    t.Anio,
    t.Cuatrimestre,
    c.Sucursal_Id,
    m.Material_Tipo,
    SUM(c.Detalle_Subtotal) AS Total_Gastado
FROM DATA_DEALERS.BI_Hechos_Compras c
    JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON c.Tiempo_Id = t.Tiempo_Id
    JOIN DATA_DEALERS.BI_Dimension_Tipo_Material m ON c.Tipo_Material_Id = m.Tipo_Material_Id
GROUP BY 
    t.Anio, 
    t.Cuatrimestre, 
    c.Sucursal_Id, 
    m.Material_Tipo;

-- 9. Porcentaje de cumplimiento de envíos en los tiempos programados por mes.
--     Se calcula teniendo en cuenta los envíos cumplidos en fecha sobre el total de
--     envíos para el período.
--     [ENVIOS]

CREATE VIEW DATA_DEALERS.VW_Cumplimiento_Envios AS
SELECT 
    t.Anio,
    t.Mes,
    e.Sucursal_Id,
    (SUM(CAST(e.Cantidad_Cumplidos AS FLOAT)) / NULLIF(SUM(e.Cantidad_Envios), 0)) * 100 AS Porcentaje_Cumplimiento
FROM DATA_DEALERS.BI_Hechos_Envios e
    JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON e.Tiempo_Id = t.Tiempo_Id
GROUP BY 
    t.Anio, 
    t.Mes, 
    e.Sucursal_Id;

-- 10. Localidades que pagan mayor costo de envío. Las 3 localidades (tomando la
--     localidad del cliente) con mayor promedio de costo de envío (total).
--     [ENVIO] VENTAS??

CREATE VIEW DATA_DEALERS.VW_Localidades_Costo_Envio AS
SELECT TOP 3 
    u.Localidad,
    AVG(e.Total_Costo_Envios) AS Costo_Promedio
FROM DATA_DEALERS.BI_Hechos_Envios e
    JOIN DATA_DEALERS.BI_Dimension_Ubicacion u ON e.Ubicacion_Id = u.Ubicacion_Id
GROUP BY u.Localidad
ORDER BY Costo_Promedio DESC;
*/
------------------------------ MIGRACION -----------------------------

--------- CREACION DE PROCEDURES ---------

-- Dimensiones

GO
CREATE PROCEDURE DATA_DEALERS.migrate_dimension_tiempo
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Dimension_Tiempo(Anio, Cuatrimestre, Mes)
    (
    SELECT DISTINCT 
        YEAR(Factura_Fecha) AS Anio,
        DATEPART(QUARTER, Factura_Fecha) AS Cuatrimestre,
        MONTH(Factura_Fecha) AS Mes
    FROM DATA_DEALERS.Factura
    UNION 
    SELECT DISTINCT 
        YEAR(Pedido_Fecha) AS Anio,
        DATEPART(QUARTER, Pedido_Fecha) AS Cuatrimestre,
        MONTH(Pedido_Fecha) AS Mes
    FROM DATA_DEALERS.Pedido
    UNION
    SELECT DISTINCT 
        YEAR(Compra_Fecha) AS Anio,
        DATEPART(QUARTER, Compra_Fecha) AS Cuatrimestre,
        MONTH(Compra_Fecha) AS Mes
    FROM DATA_DEALERS.Compra
    UNION
    SELECT DISTINCT 
        YEAR(Envio_Fecha_Programada) AS Anio,
        DATEPART(QUARTER, Envio_Fecha_Programada) AS Cuatrimestre,
        MONTH(Envio_Fecha_Programada) AS Mes
    FROM DATA_DEALERS.Envio
    UNION
    SELECT DISTINCT 
        YEAR(Envio_Fecha) AS Anio,
        DATEPART(QUARTER, Envio_Fecha) AS Cuatrimestre,
        MONTH(Envio_Fecha) AS Mes
    FROM DATA_DEALERS.Envio
    )
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_dimension_ubicacion
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Dimension_Ubicacion(Provincia, Localidad)
    (
    SELECT DISTINCT 
        p.Provincia_Nombre, 
        l.Localidad_Nombre
    FROM DATA_DEALERS.Cliente c
        JOIN DATA_DEALERS.Direccion d ON c.Cliente_Direccion = d.Direccion_Codigo
        JOIN DATA_DEALERS.Localidad l ON d.Localidad_Codigo = l.Localidad_Codigo
        JOIN DATA_DEALERS.Provincia p ON l.Provincia_Codigo = p.Provincia_Codigo
    UNION
    SELECT DISTINCT 
        p.Provincia_Nombre, 
        l.Localidad_Nombre
    FROM DATA_DEALERS.Sucursal s
        JOIN DATA_DEALERS.Direccion d ON s.Sucursal_Direccion = d.Direccion_Codigo
        JOIN DATA_DEALERS.Localidad l ON d.Localidad_Codigo = l.Localidad_Codigo
        JOIN DATA_DEALERS.Provincia p ON l.Provincia_Codigo = p.Provincia_Codigo
    )
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_dimension_rango_etario_clientes
AS 
BEGIN
    INSERT INTO DATA_DEALERS.BI_Dimension_Rango_Etario_Clientes(Edad_Minima, Edad_Maxima)
    VALUES 
        (0, 24),
        (25, 34),
        (35, 49),
        (50, 255)
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_dimension_turno_ventas
AS 
BEGIN
    INSERT INTO DATA_DEALERS.BI_Dimension_Turno_Ventas(Horario_Minimo, Horario_Maximo)
    VALUES 
        (8, 13),
        (14, 20)
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_dimension_tipo_material
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Dimension_Tipo_Material(Tipo_Material)
    VALUES 
        ('Madera'), 
        ('Relleno'), 
        ('Tela')
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_dimension_modelo_sillon
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Dimension_Modelo_Sillon(Nombre_Modelo)
    SELECT Sillon_Modelo
    FROM DATA_DEALERS.Sillon_Modelo
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_dimension_estado_pedido
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Dimension_Estado_Pedido(Estado_Pedido)
    VALUES 
        ('PENDIENTE'),
        ('CANCELADO'),
        ('ENTREGADO')
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_dimension_sucursal
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Dimension_Sucursal(Sucursal_NroSucursal)
    SELECT Sucursal_NroSucursal
    FROM DATA_DEALERS.Sucursal
END
GO

-- Hechos

CREATE PROCEDURE DATA_DEALERS.migrate_hechos_ventas
AS
BEGIN
    -- Inserta los datos transformados en la tabla BI_Hechos_Ventas
    INSERT INTO DATA_DEALERS.BI_Hechos_Ventas(Detalle_Factura_Numero, Factura_Numero, Modelo_Sillon_Id, Rango_Etario_Id, Tiempo_Id, Ubicacion_Id, Sucursal_Id, Detalle_Subtotal, Detalle_Cantidad, Detalle_Tiempo_Fabricacion)
    SELECT 
        -- PKs
        df.Detalle_Factura_Numero,
        df.Factura_Numero,
        -- Ids de las dimensiones
        dm.Modelo_Sillon_Id, 
        r.Rango_Etario_Id, 
        t.Tiempo_Id, 
        u.Ubicacion_Id, 
        ds.Sucursal_Id, 
        -- Datos del detalles del factura
        df.Detalle_Factura_Subtotal,
        df.Detalle_Factura_Cantidad,
        -- Dias de fabricacion: diferencia entre la fecha del pedido y la fecha de la factura
        DATEDIFF(DAY, p.Pedido_Fecha, f.Factura_Fecha)
    FROM DATA_DEALERS.Detalle_Factura df
        JOIN DATA_DEALERS.Factura f ON df.Factura_Numero = f.Factura_Numero
        JOIN DATA_DEALERS.Pedido p ON df.Pedido_Numero = p.Pedido_Numero
        
        -- Para obtener el id de la dimension modelo sillon
        JOIN DATA_DEALERS.Detalle_Pedido dp ON df.Pedido_Numero = dp.Pedido_Numero AND df.Detalle_Factura_Numero = dp.Detalle_Pedido_Numero
        JOIN DATA_DEALERS.Sillon s ON dp.Detalle_Sillon = s.Sillon_Codigo
        JOIN DATA_DEALERS.Sillon_Modelo m ON s.Sillon_Modelo = m.Sillon_Modelo_Codigo
        JOIN DATA_DEALERS.BI_Dimension_Modelo_Sillon dm ON dm.Nombre_Modelo = m.Sillon_Modelo
        
        -- Para obtener los el id de la dimension rango etario
        JOIN DATA_DEALERS.Cliente c ON f.Factura_Cliente = c.Cliente_Id
        JOIN DATA_DEALERS.BI_Dimension_Rango_Etario_Clientes r ON 
            DATEDIFF(YEAR, c.Cliente_FechaNacimiento, f.Factura_Fecha) BETWEEN r.Edad_Minima AND r.Edad_Maxima

        -- Para obtener el id de la dimension tiempo
        JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON 
            YEAR(f.Factura_Fecha) = t.Anio AND 
            DATEPART(QUARTER, f.Factura_Fecha) = t.Cuatrimestre AND 
            MONTH(f.Factura_Fecha) = t.Mes
        
        -- Para obtener el id de la dimension ubicacion
        JOIN DATA_DEALERS.Sucursal su ON f.Factura_Sucursal = su.Sucursal_NroSucursal
        JOIN DATA_DEALERS.Direccion d ON su.Sucursal_Direccion = d.Direccion_Codigo
        JOIN DATA_DEALERS.Localidad l ON d.Localidad_Codigo = l.Localidad_Codigo
        JOIN DATA_DEALERS.Provincia pr ON l.Provincia_Codigo = pr.Provincia_Codigo
        JOIN DATA_DEALERS.BI_Dimension_Ubicacion u ON
            u.Localidad = l.Localidad_Nombre AND 
            u.Provincia = pr.Provincia_Nombre

        -- Busca el id de la dimension sucursal
        JOIN DATA_DEALERS.BI_Dimension_Sucursal ds ON f.Factura_Sucursal = ds.Sucursal_NroSucursal
END 
GO
/*
CREATE PROCEDURE DATA_DEALERS.migrate_hechos_compras
AS
BEGIN
    -- Inserta los datos transformados en la tabla BI_Hechos_Compras
    INSERT INTO DATA_DEALERS.BI_Hechos_Compras(
        Tiempo_Id, 
        Sucursal_Id, 
        Tipo_Material_Id, 
        Detalle_Subtotal
    )
    SELECT 
        t.Tiempo_Id,
        ds.Sucursal_Id,
        dt.Tipo_Material_Id,
        SUM(dc.Detalle_Compra_Subtotal)
    FROM DATA_DEALERS.Detalle_Compra dc
        JOIN DATA_DEALERS.Compra c ON dc.Compra_Numero = c.Compra_Numero
        
        -- Para obtener el id de la dimension tiempo
        JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON YEAR(c.Compra_Fecha) + DATEPART(QUARTER, c.Compra_Fecha) + MONTH(c.Compra_Fecha) = t.Anio + t.Cuatrimestre + t.Mes
        
        -- Para obtener el id de la dimension sucursal
        JOIN DATA_DEALERS.Sucursal su ON c.Compra_Sucursal = su.Sucursal_NroSucursal
        JOIN DATA_DEALERS.BI_Dimension_Sucursal ds ON su.Sucursal_NroSucursal = ds.Sucursal_NroSucursal
        
        -- Para obtener el id de la dimension tipo material
        JOIN DATA_DEALERS.Material m ON dc.Detalle_Compra_Material = m.Material_Codigo
        JOIN DATA_DEALERS.BI_Dimension_Tipo_Material dt ON m.Material_Tipo = dt.Tipo_Material
    GROUP BY 
        t.Tiempo_Id, 
        ds.Sucursal_Id, 
        dt.Tipo_Material_Id
END
GO
*/
--------- EXEC PROCEDURES ---------

EXEC DATA_DEALERS.migrate_dimension_tiempo
EXEC DATA_DEALERS.migrate_dimension_ubicacion
EXEC DATA_DEALERS.migrate_dimension_rango_etario_clientes
EXEC DATA_DEALERS.migrate_dimension_turno_ventas
EXEC DATA_DEALERS.migrate_dimension_tipo_material
EXEC DATA_DEALERS.migrate_dimension_modelo_sillon
EXEC DATA_DEALERS.migrate_dimension_estado_pedido
EXEC DATA_DEALERS.migrate_dimension_sucursal
EXEC DATA_DEALERS.migrate_hechos_ventas
EXEC DATA_DEALERS.migrate_hechos_compras
EXEC DATA_DEALERS.migrate_hechos_envios
EXEC DATA_DEALERS.migrate_hechos_pedidos

------------------------------- ELIMINACION DE ESTRUCTURAS 

DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_tiempo;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_ubicacion;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_rango_etario_clientes;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_turno_ventas;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_tipo_material;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_modelo_sillon;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_estado_pedido;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_sucursal;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_hechos_ventas;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_hechos_compras;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_hechos_envios;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_hechos_pedidos;


-----------------------------

/*
-- Eliminar vistas
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql + 'DROP VIEW IF EXISTS ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) + ';' + CHAR(13)
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'DATA_DEALERS';

EXEC sp_executesql @sql;

-- Eliminar restricciones de claves foráneas de las tablas que empiezan con 'BI'
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql + 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME) + '.' + QUOTENAME(PARENT_OBJECT_NAME) + 
               ' DROP CONSTRAINT ' + QUOTENAME(NAME) + ';' + CHAR(13)
FROM sys.foreign_keys fk
JOIN sys.objects o ON fk.parent_object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE s.name = 'DATA_DEALERS' AND o.name LIKE 'BI%';

EXEC sp_executesql @sql;

-- Eliminar las tablas que comienzan con 'DATA_DEALERS.BI'
DECLARE @sql NVARCHAR(MAX) = '';
SET @sql = '';
SELECT @sql = @sql + 'DROP TABLE IF EXISTS ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) + ';' + CHAR(13)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'DATA_DEALERS' AND TABLE_NAME LIKE 'BI%';

EXEC sp_executesql @sql;