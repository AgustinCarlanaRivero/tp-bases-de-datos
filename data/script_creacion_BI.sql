-- Aclaracion: Lo que no esta comentado en el codigo, esta en el archivo Estrategia.pdf

USE GD1C2025 -- Asegurarse de usar la base de datos correcta

---------------------------- CREACION DE TABLAS ----------------------------

--------- DIMENSIONES ---------

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

--------- HECHOS ---------

CREATE TABLE DATA_DEALERS.BI_Hechos_Facturas (
    Modelo_Sillon_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Modelo_Sillon,
    Rango_Etario_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Rango_Etario_Clientes,
    Tiempo_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Ubicacion_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Ubicacion,
    Sucursal_Id BIGINT NOT NULL REFERENCES  DATA_DEALERS.BI_Dimension_Sucursal,
    Ingresos DECIMAL(38,2) NOT NULL,
    Cantidad_Facturas BIGINT NOT NULL,
    Promedio_Tiempo_Fabricacion DECIMAL(6,2) NOT NULL,
    PRIMARY KEY (Modelo_Sillon_Id, Rango_Etario_Id, Tiempo_Id, Ubicacion_Id, Sucursal_Id)
)

CREATE TABLE DATA_DEALERS.BI_Hechos_Compras (
    Tiempo_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Sucursal_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Sucursal,
    Tipo_Material_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Tipo_Material,
    Egresos DECIMAL(38,2) NOT NULL,
    Cantidad_Compras BIGINT NOT NULL,
    PRIMARY KEY (Tiempo_Id, Sucursal_Id, Tipo_Material_Id)
)

CREATE TABLE DATA_DEALERS.BI_Hechos_Pedidos (
    Tiempo_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Sucursal_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Sucursal,
    Estado_Pedido_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Estado_Pedido,
    Turno_Ventas_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Turno_Ventas,
    Cantidad_Pedidos BIGINT NOT NULL,
    PRIMARY KEY (Tiempo_Id, Sucursal_Id, Estado_Pedido_Id, Turno_Ventas_Id)
)

CREATE TABLE DATA_DEALERS.BI_Hechos_Envios (
    Tiempo_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Ubicacion_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Ubicacion,
    Sucursal_Id BIGINT NOT NULL REFERENCES DATA_DEALERS.BI_Dimension_Sucursal,
    Cantidad_Envios BIGINT NOT NULL,
    Cantidad_Envios_Cumplidos_En_Fecha BIGINT NOT NULL,
    Costo_Envios BIGINT NOT NULL,
    PRIMARY KEY (Tiempo_Id, Ubicacion_Id, Sucursal_Id)
)

---------------------------- PROCEDURES DE MIGRACION ----------------------------

--------- CREACION ---------

--------- DIMENSIONES ---------

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

--------- HECHOS ---------

CREATE PROCEDURE DATA_DEALERS.migrate_hechos_facturas
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Hechos_Facturas(Modelo_Sillon_Id, Rango_Etario_Id, Tiempo_Id, Ubicacion_Id, Sucursal_Id, Ingresos, Cantidad_Facturas, Promedio_Tiempo_Fabricacion)
    SELECT 
        -- PKs
        dm.Modelo_Sillon_Id, 
        r.Rango_Etario_Id, 
        t.Tiempo_Id, 
        u.Ubicacion_Id, 
        ds.Sucursal_Id, 
        -- Atributos propios
        SUM(df.Detalle_Factura_Precio * df.Detalle_Factura_Cantidad), --Justificacion: No tenemos en cuenta el envio aca
        (  
            SELECT COUNT(DISTINCT fac.Factura_Numero)
            FROM DATA_DEALERS.Factura fac
                JOIN DATA_DEALERS.Cliente c2 ON fac.Factura_Cliente = c2.Cliente_Id
                JOIN DATA_DEALERS.BI_Dimension_Rango_Etario_Clientes r2 ON 
                    DATEDIFF(YEAR, c2.Cliente_FechaNacimiento, fac.Factura_Fecha) BETWEEN r2.Edad_Minima AND r2.Edad_Maxima
                JOIN DATA_DEALERS.BI_Dimension_Tiempo t2 ON
                    YEAR(fac.Factura_Fecha) = t2.Anio AND 
                    DATEPART(QUARTER, fac.Factura_Fecha) = t2.Cuatrimestre AND 
                    MONTH(fac.Factura_Fecha) = t2.Mes
                JOIN DATA_DEALERS.Sucursal su2 ON fac.Factura_Sucursal = su2.Sucursal_NroSucursal
                JOIN DATA_DEALERS.Direccion d2 ON su2.Sucursal_Direccion = d2.Direccion_Codigo
                JOIN DATA_DEALERS.Localidad l2 ON d2.Localidad_Codigo = l2.Localidad_Codigo
                JOIN DATA_DEALERS.Provincia pr2 ON l2.Provincia_Codigo = pr2.Provincia_Codigo
                JOIN DATA_DEALERS.BI_Dimension_Ubicacion u2 ON
                    u2.Localidad = l2.Localidad_Nombre AND
                    u2.Provincia = pr2.Provincia_Nombre
                JOIN DATA_DEALERS.BI_Dimension_Sucursal ds2 ON fac.Factura_Sucursal = ds2.Sucursal_NroSucursal
            WHERE
                r2.Rango_Etario_Id = r.Rango_Etario_Id AND
                t2.Tiempo_Id = t.Tiempo_Id AND
                u2.Ubicacion_Id = u.Ubicacion_Id AND
                ds2.Sucursal_Id = ds.Sucursal_Id
        ), -- Justificacion: Se usa COUNT para obtener la cantidad de ventas por cada grupo de dimensiones
        AVG(DATEDIFF(DAY, p.Pedido_Fecha, f.Factura_Fecha)) --Justificacion: Promedio de la diferencia entre fecha factura y fecha pedido
    FROM DATA_DEALERS.Detalle_Factura df
        JOIN DATA_DEALERS.Factura f ON f.Factura_Numero = df.Factura_Numero
        JOIN DATA_DEALERS.Pedido p ON df.Pedido_Numero = p.Pedido_Numero

        -- Para obtener el id de la dimension modelo sillon
        JOIN DATA_DEALERS.Detalle_Pedido dp ON 
            dp.Pedido_Numero = df.Pedido_Numero AND 
            dp.Detalle_Pedido_Numero = df.Detalle_Factura_Numero
        JOIN DATA_DEALERS.Sillon s ON s.Sillon_Codigo = dp.Detalle_Sillon
        JOIN DATA_DEALERS.Sillon_Modelo m ON m.Sillon_Modelo_Codigo = s.Sillon_Modelo   
        JOIN DATA_DEALERS.BI_Dimension_Modelo_Sillon dm ON m.Sillon_Modelo = dm.Nombre_Modelo
        
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
    GROUP BY
        dm.Modelo_Sillon_Id,
        r.Rango_Etario_Id,
        t.Tiempo_Id,
        u.Ubicacion_Id,
        ds.Sucursal_Id
END 
GO

CREATE PROCEDURE DATA_DEALERS.migrate_hechos_compras
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Hechos_Compras(Tiempo_Id, Sucursal_Id, Tipo_Material_Id, Egresos, Cantidad_Compras)
    SELECT
        -- PKs
        t.Tiempo_Id,
        s.Sucursal_Id,
        tm.Tipo_Material_Id,
        -- Atributos propios
        SUM(dc.Detalle_Compra_Subtotal),
        COUNT(DISTINCT c.Compra_Numero)
    FROM DATA_DEALERS.Detalle_Compra dc
        -- Para obtener el id de la dimension tiempo
        JOIN DATA_DEALERS.Compra c ON dc.Compra_Numero = c.Compra_Numero
        JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON 
            YEAR(c.Compra_Fecha) = t.Anio AND 
            DATEPART(QUARTER, c.Compra_Fecha) = t.Cuatrimestre AND 
            MONTH(c.Compra_Fecha) = t.Mes
        
        -- Para obtener el id de la dimension sucursal
        JOIN DATA_DEALERS.BI_Dimension_Sucursal s ON c.Compra_Sucursal = s.Sucursal_NroSucursal
        
        -- Para obtener el id de la dimension tipo material
        JOIN DATA_DEALERS.Material m ON dc.Detalle_Compra_Material = m.Material_Codigo
        JOIN DATA_DEALERS.BI_Dimension_Tipo_Material tm ON m.Material_Tipo = tm.Tipo_Material
    GROUP BY
        t.Tiempo_Id,
        s.Sucursal_Id,
        tm.Tipo_Material_Id
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_hechos_pedidos
AS
BEGIN
    INSERT INTO DATA_DEALERS.BI_Hechos_Pedidos(Tiempo_Id, Sucursal_Id, Estado_Pedido_Id, Turno_Ventas_Id, Cantidad_Pedidos)
    SELECT 
        -- PKs
        t.Tiempo_Id,
        s.Sucursal_Id,
        e.Estado_Pedido_Id,
        tv.Turno_Ventas_Id,
        -- Atributos propios
        COUNT(DISTINCT p.Pedido_Numero)
    FROM DATA_DEALERS.Pedido p
        -- Para obtener el id de la dimension tiempo
        JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON 
            YEAR(p.Pedido_Fecha) = t.Anio AND 
            DATEPART(QUARTER, p.Pedido_Fecha) = t.Cuatrimestre AND 
            MONTH(p.Pedido_Fecha) = t.Mes
        
        -- Para obtener el id de la dimension sucursal
        JOIN DATA_DEALERS.BI_Dimension_Sucursal s ON p.Pedido_Sucursal = s.Sucursal_NroSucursal
        
        -- Para obtener el id de la dimension estado pedido
        JOIN DATA_DEALERS.BI_Dimension_Estado_Pedido e ON p.Pedido_Estado = e.Estado_Pedido
        
        -- Para obtener el id de la dimension turno ventas
        JOIN DATA_DEALERS.BI_Dimension_Turno_Ventas tv ON 
            DATEPART(HOUR, p.Pedido_Fecha) BETWEEN tv.Horario_Minimo AND tv.Horario_Maximo
    GROUP BY
        t.Tiempo_Id,
        s.Sucursal_Id,
        e.Estado_Pedido_Id,
        tv.Turno_Ventas_Id
END
GO

CREATE PROCEDURE DATA_DEALERS.migrate_hechos_envios
AS 
BEGIN
    INSERT INTO DATA_DEALERS.BI_Hechos_Envios(
        Tiempo_Id, 
        Ubicacion_Id, 
        Sucursal_Id, 
        Cantidad_Envios, 
        Cantidad_Envios_Cumplidos_En_Fecha, 
        Costo_Envios
    )
    SELECT 
        t.Tiempo_Id,    
        u.Ubicacion_Id,
        s.Sucursal_Id,
        COUNT(DISTINCT e.Envio_Numero),
        COUNT(DISTINCT CASE 
                WHEN 
                    e.Envio_Fecha IS NOT NULL AND 
                    e.Envio_Fecha <= e.Envio_Fecha_Programada 
                THEN e.Envio_Numero 
                ELSE NULL 
                END
            ), -- Cuenta los envíos cumplidos en fecha para el grupo actual
        SUM(e.Envio_Total)
    FROM DATA_DEALERS.Envio e
        -- Dimensión tiempo según la fecha programada del envío
        JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON 
            YEAR(e.Envio_Fecha_Programada) = t.Anio AND 
            DATEPART(QUARTER, e.Envio_Fecha_Programada) = t.Cuatrimestre AND 
            MONTH(e.Envio_Fecha_Programada) = t.Mes
        -- Dimensión ubicación según la dirección del cliente de la factura asociada
        JOIN DATA_DEALERS.Factura f ON e.Envio_Factura = f.Factura_Numero
        JOIN DATA_DEALERS.Cliente c ON f.Factura_Cliente = c.Cliente_Id
        JOIN DATA_DEALERS.Direccion d ON c.Cliente_Direccion = d.Direccion_Codigo
        JOIN DATA_DEALERS.Localidad l ON d.Localidad_Codigo = l.Localidad_Codigo
        JOIN DATA_DEALERS.Provincia p ON l.Provincia_Codigo = p.Provincia_Codigo
        JOIN DATA_DEALERS.BI_Dimension_Ubicacion u ON 
            u.Localidad = l.Localidad_Nombre AND 
            u.Provincia = p.Provincia_Nombre
        -- Dimensión sucursal según la sucursal de la factura asociada
        JOIN DATA_DEALERS.BI_Dimension_Sucursal s ON f.Factura_Sucursal = s.Sucursal_NroSucursal
    GROUP BY
        t.Tiempo_Id,
        u.Ubicacion_Id,
        s.Sucursal_Id
END
GO

--------- EXEC ---------

EXEC DATA_DEALERS.migrate_dimension_tiempo
EXEC DATA_DEALERS.migrate_dimension_ubicacion
EXEC DATA_DEALERS.migrate_dimension_rango_etario_clientes
EXEC DATA_DEALERS.migrate_dimension_turno_ventas
EXEC DATA_DEALERS.migrate_dimension_tipo_material
EXEC DATA_DEALERS.migrate_dimension_modelo_sillon
EXEC DATA_DEALERS.migrate_dimension_estado_pedido
EXEC DATA_DEALERS.migrate_dimension_sucursal
EXEC DATA_DEALERS.migrate_hechos_facturas
EXEC DATA_DEALERS.migrate_hechos_pedidos
EXEC DATA_DEALERS.migrate_hechos_envios

---------------------------- VISTAS ----------------------------

-- 1. Ganancias: Total de ingresos (facturación) - total de egresos (compras), por
--     cada mes, por cada sucursal.
--     [VENTAS, COMPRAS, ENVIOS]

CREATE VIEW DATA_DEALERS.VW_Ganancias_Mensuales AS
SELECT 
    t.Anio,
    t.Mes,
    s.Sucursal_NroSucursal,
    SUM(f.Ingresos) + 
    ISNULL(e.Total_Costo_Envios, 0) - 
    ISNULL(c.Total_Egresos,0) AS Ganancias
FROM DATA_DEALERS.BI_Hechos_Facturas f
    LEFT JOIN (
        SELECT 
            Tiempo_Id,
            Sucursal_Id,
            SUM(Costo_Envios) AS Total_Costo_Envios
        FROM DATA_DEALERS.BI_Hechos_Envios
        GROUP BY 
            Tiempo_Id, 
            Sucursal_Id
    ) e ON e.Tiempo_Id = f.Tiempo_Id AND e.Sucursal_Id = f.Sucursal_Id
    LEFT JOIN (
        SELECT 
            Tiempo_Id,
            Sucursal_Id,
            SUM(Egresos) AS Total_Egresos
        FROM DATA_DEALERS.BI_Hechos_Compras
        GROUP BY 
            Tiempo_Id, 
            Sucursal_Id
    ) c ON 
        c.Tiempo_Id = f.Tiempo_Id AND 
        c.Sucursal_Id = f.Sucursal_Id
    LEFT JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON f.Tiempo_Id = t.Tiempo_Id
    LEFT JOIN DATA_DEALERS.BI_Dimension_Sucursal s ON f.Sucursal_Id = s.Sucursal_Id
GROUP BY
    t.Anio,
    t.Mes,
    s.Sucursal_NroSucursal,
    e.Total_Costo_Envios,
    c.Total_Egresos
GO


-- 2.Factura promedio mensual. Valor promedio de las facturas (en $) según la
--     provincia de la sucursal para cada cuatrimestre de cada Anio. Se calcula en
--     función de la sumatoria del importe fde las facturas sobre el total de las mismas
--     durante dicho período.
--     [VENTAS]

CREATE VIEW DATA_DEALERS.VW_Factura_Promedio_Mensual AS
SELECT 
    t.Anio,
    t.Cuatrimestre,
    u.Provincia,
    ((SUM(f.Ingresos) + ISNULL(e.Total_Costo_Envios,0)) / SUM(f.Cantidad_Facturas)) / 4 AS Factura_Promedio
FROM DATA_DEALERS.BI_Hechos_Facturas f
    LEFT JOIN (
        SELECT 
            Tiempo_Id,
            SUM(Costo_Envios) AS Total_Costo_Envios
        FROM DATA_DEALERS.BI_Hechos_Envios 
        GROUP BY 
            Tiempo_Id
    ) e ON e.Tiempo_Id = f.Tiempo_Id
    LEFT JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON f.Tiempo_Id = t.Tiempo_Id
    LEFT JOIN DATA_DEALERS.BI_Dimension_Ubicacion u ON f.Ubicacion_Id = u.Ubicacion_Id
GROUP BY
    t.Anio,
    t.Cuatrimestre,
    u.Provincia,
    e.Total_Costo_Envios
    
GO
-- 3. Rendimiento de modelos. Los 3 modelos con mayores ventas para cada
--     cuatrimestre de cada Anio según la localidad de la sucursal y rango etario de los
--     clientes.
--     [VENTAS]


CREATE VIEW DATA_DEALERS.VW_Top3_Modelos_Cuatrimestral AS
GO

/*CREATE VIEW DATA_DEALERS.VW_Top3_Modelos_Cuatrimestral AS
SELECT TOP 3
    dms.Modelo_Sillon,
    SUM(fh.Ingresos) AS TotalVentasGlobales
FROM
    DATA_DEALERS.BI_Hechos_Facturas fh
INNER JOIN
    DATA_DEALERS.BI_Dimension_Modelo_Sillon dms ON fh.Modelo_Sillon_Id = dms.Modelo_Sillon_Id
GROUP BY
    dms.Modelo_Sillon
ORDER BY
    TotalVentasGlobales DESC;*/

/*CREATE VIEW DATA_DEALERS.VW_Top3_Modelos_Cuatrimestral AS
SELECT 
    Modelo_Sillon_Id
FROM (
    SELECT 
        t.Anio,
        t.Cuatrimestre,
        u.Localidad,
        f.Rango_Etario_Id,
        f.Modelo_Sillon_Id,
        SUM(f.Cantidad_Facturas) AS Total_Ventas,
        RANK() OVER (
            PARTITION BY t.Anio, t.Cuatrimestre, u.Localidad, f.Rango_Etario_Id
            ORDER BY SUM(f.Cantidad_Facturas) DESC
        ) AS Ranking
    FROM DATA_DEALERS.BI_Hechos_Facturas f
        JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON f.Tiempo_Id = t.Tiempo_Id
        JOIN DATA_DEALERS.BI_Dimension_Ubicacion u ON f.Ubicacion_Id = u.Ubicacion_Id
    GROUP BY 
        t.Anio,
        t.Cuatrimestre,
        u.Localidad,
        f.Rango_Etario_Id,
        f.Modelo_Sillon_Id
) AS TopModelos
WHERE Ranking <= 3;
GO*/
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
GO

-- 5. Conversión de pedidos. Porcentaje de pedidos según estado, por cuatrimestre y
--     sucursal.
--     [PEDIDOS]

CREATE VIEW DATA_DEALERS.VW_Conversion_Pedidos AS
SELECT 
    t.Anio,
    t.Cuatrimestre,
    p.Sucursal_Id,
    e.Estado_Pedido,
    COUNT(DISTINCT p.Pedido_Numero) * 100.0 / 
FROM DATA_DEALERS.BI_Hechos_Pedidos p
    JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON p.Tiempo_Id = t.Tiempo_Id
    JOIN DATA_DEALERS.BI_Dimension_Estado_Pedido e ON p.Estado_Pedido_Id = e.Estado_Pedido_Id
GROUP BY 
    t.Anio, 
    t.Cuatrimestre, 
    p.Sucursal_Id, 
    e.Estado_Pedido;
GO

-- 6. Tiempo promedio de fabricación: Tiempo promedio que tarda cada sucursal
--     entre que se registra un pedido y registra la factura para el mismo. Por
--     cuatrimestre.
--     [PEDIDOS, VENTAS]

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
GO

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
GO

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
GO

-- 9. Porcentaje de cumplimiento de envíos en los tiempos programados por mes.
--     Se calcula teniendo en cuenta los envíos cumplidos en fecha sobre el total de
--     envíos para el período.
--     [ENVIOS]

CREATE VIEW DATA_DEALERS.VW_Cumplimiento_Envios AS
SELECT 
    t.Anio,
    t.Mes,
    e.Sucursal_Id,
    (SUM(CAST(e.Cantidad_Envios_Cumplidos_En_Fecha AS FLOAT)) / NULLIF(SUM(e.Cantidad_Envios), 0)) * 100 AS Porcentaje_Cumplimiento
FROM DATA_DEALERS.BI_Hechos_Envios e
    JOIN DATA_DEALERS.BI_Dimension_Tiempo t ON e.Tiempo_Id = t.Tiempo_Id
GROUP BY 
    t.Anio, 
    t.Mes, 
    e.Sucursal_Id;
GO

-- 10. Localidades que pagan mayor costo de envío. Las 3 localidades (tomando la
--     localidad del cliente) con mayor promedio de costo de envío (total).
--     [ENVIO]

CREATE VIEW DATA_DEALERS.VW_Localidades_Costo_Envio AS
SELECT TOP 3 
    u.Localidad,
    AVG(e.Costo_Envios) AS Costo_Promedio
FROM DATA_DEALERS.BI_Hechos_Envios e
    JOIN DATA_DEALERS.BI_Dimension_Ubicacion u ON e.Ubicacion_Id = u.Ubicacion_Id
GROUP BY u.Localidad
ORDER BY Costo_Promedio DESC;



------------------------------- ELIMINACION DE ESTRUCTURAS 

DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_tiempo;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_ubicacion;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_rango_etario_clientes;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_turno_ventas;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_tipo_material;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_modelo_sillon;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_estado_pedido;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_dimension_sucursal;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_hechos_facturas;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_hechos_compras;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_hechos_envios;
DROP PROCEDURE IF EXISTS DATA_DEALERS.migrate_hechos_pedidos;

DROP VIEW IF EXISTS DATA_DEALERS.VW_Ganancias_Mensuales;
DROP VIEW IF EXISTS DATA_DEALERS.VW_Factura_Promedio_Mensual;
DROP VIEW IF EXISTS DATA_DEALERS.VW_Top3_Modelos_Cuatrimestral;
DROP VIEW IF EXISTS DATA_DEALERS.VW_Volumen_Pedidos;
DROP VIEW IF EXISTS DATA_DEALERS.VW_Conversion_Pedidos;
DROP VIEW IF EXISTS DATA_DEALERS.VW_Tiempo_Promedio_Fabricacion;
DROP VIEW IF EXISTS DATA_DEALERS.VW_Promedio_Compras_Mensual;
DROP VIEW IF EXISTS DATA_DEALERS.VW_Compras_Por_Material;

/*
CREATE PROCEDURE SOLO_QUEDA_LLORAR.sp_load_HECHO_FACTURA
AS
BEGIN
    SET NOCOUNT ON;

    WITH FacturaGrupos AS (
        SELECT 
            f.fact_nro AS factura,
            SOLO_QUEDA_LLORAR.fn_ObtenerDimTiempo(f.fact_fecha) AS tiempo,
            ds.dim_sill_nro AS modelo,
            du.dim_ubic_nro AS ubicacion,
            SOLO_QUEDA_LLORAR.fn_ObtenerDimRangoEtario(c.clie_fecha_nac) AS rango_etario,
            dsu.dim_sucu_nro AS sucursal,
            df.deta_fac_subtotal AS subtotal,
            df.deta_fac_cantidad AS cantidad,
            e.envi_total AS envio
        FROM SOLO_QUEDA_LLORAR.DETALLE_FACTURA df
        JOIN SOLO_QUEDA_LLORAR.FACTURA f ON df.deta_fac_factura = f.fact_nro
        JOIN SOLO_QUEDA_LLORAR.DETALLE_PEDIDO dp ON dp.deta_ped_nro = df.deta_fac_pedido
        JOIN SOLO_QUEDA_LLORAR.SILLON s ON s.sill_nro = dp.deta_ped_sillon
        JOIN SOLO_QUEDA_LLORAR.DIMENSION_MODELO_SILLON ds ON ds.dim_sill_nro = s.sill_modelo
        JOIN SOLO_QUEDA_LLORAR.SUCURSAL sc ON sc.sucu_nro = f.fact_sucursal
        JOIN SOLO_QUEDA_LLORAR.DIRECCION d ON d.dire_nro = sc.sucu_direccion
        JOIN SOLO_QUEDA_LLORAR.LOCALIDAD l ON l.loca_nro = d.dire_localidad
        JOIN SOLO_QUEDA_LLORAR.DIMENSION_UBICACION du 
            ON du.dim_ubic_loca_nro = d.dire_localidad AND du.dim_ubic_prov_nro = l.loca_provi
        JOIN SOLO_QUEDA_LLORAR.DIMENSION_SUCURSAL dsu ON dsu.dim_sucu_sucursal = f.fact_sucursal
        JOIN SOLO_QUEDA_LLORAR.CLIENTE c ON c.clie_nro = f.fact_cliente
        JOIN SOLO_QUEDA_LLORAR.ENVIO e ON f.fact_nro = e.envi_factura
    ),
    FacturaTotales AS (
        SELECT
            factura, 
            SUM(subtotal) + MAX(envio) AS subtotal_total,  
            SUM(cantidad) AS cantidad_total
        FROM FacturaGrupos
        GROUP BY factura
    ),
    FacturaGruposUnicos AS (
        SELECT DISTINCT
            factura,
            tiempo,
            modelo,
            ubicacion,
            rango_etario,
            sucursal
        FROM FacturaGrupos
    ),
    FacturaConteoGrupos AS (
        SELECT
            factura,
            COUNT(*) AS grupos_por_factura
        FROM FacturaGruposUnicos
        GROUP BY factura
    ),
    FacturasConFraccion AS (
        SELECT
            fgu.factura,
            fgu.tiempo,
            fgu.modelo,
            fgu.ubicacion,
            fgu.rango_etario,
            fgu.sucursal,
            ft.subtotal_total,
            ft.cantidad_total,
            CAST(1.0 AS DECIMAL(18,10)) / NULLIF(fcg.grupos_por_factura, 0) AS factura_fraccion
        FROM FacturaGruposUnicos fgu
        JOIN FacturaConteoGrupos fcg ON fgu.factura = fcg.factura
        JOIN FacturaTotales ft ON fgu.factura = ft.factura
    )
    INSERT INTO SOLO_QUEDA_LLORAR.HECHO_FACTURA (hec_fact_tiempo,  hec_fact_sillon, hec_fact_ubic, hec_fact_rango_eta, hec_fact_sucursal, hec_fact_subtotal,hec_fact_cant_sillones, hec_fact_cant_facturas)
    SELECT
        tiempo,
        modelo,
        ubicacion,
        rango_etario,
        sucursal,
        SUM(subtotal_total * factura_fraccion) AS hec_fact_subtotal,
        round(SUM(cantidad_total * factura_fraccion),0) AS hec_fact_cant_sillones,
        SUM(factura_fraccion) AS hec_fact_cant_facturas
    FROM FacturasConFraccion
    GROUP BY tiempo, modelo, ubicacion, rango_etario, sucursal;

END
GO
*/

/*CREATE PROCEDURE DATA_DEALERS.migrate_hechos_facturas AS 
BEGIN 
    INSERT INTO DATA_DEALERS.BI_Hechos_Facturas(
        Modelo_Sillon_Id, 
        Rango_Etario_Id, 
        Tiempo_Id, 
        Ubicacion_Id, 
        Sucursal_Id, 
        Ingresos, 
        Cantidad_Facturas_Filtradas, 
        Promedio_Tiempo_Fabricacion
    )     
    SELECT          
        -- PKs         
        dm.Modelo_Sillon_Id,          
        r.Rango_Etario_Id,          
        t.Tiempo_Id,          
        u.Ubicacion_Id,          
        ds.Sucursal_Id,          
        
        -- Atributos propios         
        SUM(df.Detalle_Factura_Precio * df.Detalle_Factura_Cantidad), -- Ingresos
        
        -- OPCIÓN 1: Contar líneas de factura (más preciso para análisis por modelo)
        COUNT(*), -- Cantidad de líneas de detalle para esta combinación de dimensiones
        
        -- OPCIÓN 2: Si quieres facturas únicas, usar una proporción
        -- COUNT(DISTINCT f.Factura_Numero) * 1.0 / COUNT(DISTINCT dm.Modelo_Sillon_Id), 
        
        -- OPCIÓN 3: Usar subquery con ventana para dividir facturas proporcionalmente
        -- SUM(1.0 / (SELECT COUNT(DISTINCT dm2.Modelo_Sillon_Id) 
        --            FROM DATA_DEALERS.Detalle_Factura df2 
        --            JOIN ... [mismos joins] 
        --            WHERE df2.Factura_Numero = f.Factura_Numero))
        
        AVG(DATEDIFF(DAY, p.Pedido_Fecha, f.Factura_Fecha)) -- Promedio_Tiempo_Fabricacion
        
    FROM DATA_DEALERS.Detalle_Factura df         
        JOIN DATA_DEALERS.Factura f ON f.Factura_Numero = df.Factura_Numero         
        JOIN DATA_DEALERS.Pedido p ON df.Pedido_Numero = p.Pedido_Numero          
        
        -- Para obtener el id de la dimension modelo sillon         
        JOIN DATA_DEALERS.Detalle_Pedido dp ON              
            dp.Pedido_Numero = df.Pedido_Numero AND              
            dp.Detalle_Pedido_Numero = df.Detalle_Factura_Numero         
        JOIN DATA_DEALERS.Sillon s ON s.Sillon_Codigo = dp.Detalle_Sillon         
        JOIN DATA_DEALERS.Sillon_Modelo m ON m.Sillon_Modelo_Codigo = s.Sillon_Modelo            
        JOIN DATA_DEALERS.BI_Dimension_Modelo_Sillon dm ON m.Sillon_Modelo = dm.Nombre_Modelo                  
        
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
        
    GROUP BY         
        dm.Modelo_Sillon_Id,         
        r.Rango_Etario_Id,         
        t.Tiempo_Id,         
        u.Ubicacion_Id,         
        ds.Sucursal_Id 
END*/
/*CREATE PROCEDURE DATA_DEALERS.migrate_hechos_facturas AS 
BEGIN 
    INSERT INTO DATA_DEALERS.BI_Hechos_Facturas(
        Modelo_Sillon_Id, 
        Rango_Etario_Id, 
        Tiempo_Id, 
        Ubicacion_Id, 
        Sucursal_Id, 
        Ingresos, 
        Cantidad_Facturas_Filtradas, 
        Promedio_Tiempo_Fabricacion
    )     
    SELECT          
        -- PKs         
        dm.Modelo_Sillon_Id,          
        r.Rango_Etario_Id,          
        t.Tiempo_Id,          
        u.Ubicacion_Id,          
        ds.Sucursal_Id,          
        
        -- Atributos propios         
        SUM(df.Detalle_Factura_Precio * df.Detalle_Factura_Cantidad), -- Ingresos
        
        -- Facturas divididas proporcionalmente entre modelos
        SUM(1.0 / (
            SELECT COUNT(DISTINCT dm_inner.Modelo_Sillon_Id)
            FROM DATA_DEALERS.Detalle_Factura df_inner
                JOIN DATA_DEALERS.Detalle_Pedido dp_inner ON 
                    dp_inner.Pedido_Numero = df_inner.Pedido_Numero AND
                    dp_inner.Detalle_Pedido_Numero = df_inner.Detalle_Factura_Numero
                JOIN DATA_DEALERS.Sillon s_inner ON s_inner.Sillon_Codigo = dp_inner.Detalle_Sillon
                JOIN DATA_DEALERS.Sillon_Modelo m_inner ON m_inner.Sillon_Modelo_Codigo = s_inner.Sillon_Modelo
                JOIN DATA_DEALERS.BI_Dimension_Modelo_Sillon dm_inner ON m_inner.Sillon_Modelo = dm_inner.Nombre_Modelo
            WHERE df_inner.Factura_Numero = f.Factura_Numero
        )), -- Cantidad proporcional de facturas
        
        AVG(DATEDIFF(DAY, p.Pedido_Fecha, f.Factura_Fecha)) -- Promedio_Tiempo_Fabricacion
        
    FROM DATA_DEALERS.Detalle_Factura df         
        JOIN DATA_DEALERS.Factura f ON f.Factura_Numero = df.Factura_Numero         
        JOIN DATA_DEALERS.Pedido p ON df.Pedido_Numero = p.Pedido_Numero          
        
        -- Para obtener el id de la dimension modelo sillon         
        JOIN DATA_DEALERS.Detalle_Pedido dp ON              
            dp.Pedido_Numero = df.Pedido_Numero AND              
            dp.Detalle_Pedido_Numero = df.Detalle_Factura_Numero         
        JOIN DATA_DEALERS.Sillon s ON s.Sillon_Codigo = dp.Detalle_Sillon         
        JOIN DATA_DEALERS.Sillon_Modelo m ON m.Sillon_Modelo_Codigo = s.Sillon_Modelo            
        JOIN DATA_DEALERS.BI_Dimension_Modelo_Sillon dm ON m.Sillon_Modelo = dm.Nombre_Modelo                  
        
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
        
    GROUP BY         
        dm.Modelo_Sillon_Id,         
        r.Rango_Etario_Id,         
        t.Tiempo_Id,         
        u.Ubicacion_Id,         
        ds.Sucursal_Id 
END*/