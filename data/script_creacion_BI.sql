-- Aclaracion: Lo que no esta comentado en el codigo, esta en el archivo Estrategia.pdf

USE GD1C2025 -- Asegurarse de usar la base de datos correcta

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
    Edad_Maxima TINYINT,
    CHECK ((Edad_Minima = 0 AND Edad_Maxima = 25) OR 
           (Edad_Minima = 25 AND Edad_Maxima = 35) OR 
           (Edad_Minima = 35 AND Edad_Maxima = 50) OR 
           (Edad_Minima = 50 AND Edad_Maxima = 255))
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Turno_Ventas (
    Turno_Ventas_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Horario_Minimo TINYINT, 
    Horario_Maximo TINYINT,
    CHECK ((Horario_Minimo = 8 AND Horario_Maximo = 14) OR 
           (Horario_Minimo = 14 AND Horario_Maximo = 20))
)

CREATE TABLE DATA_DEALERS.BI_Dimension_Tipo_Material (
    Tipo_Material_Id BIGINT PRIMARY KEY IDENTITY(0, 1),
    Tela NVARCHAR(255),
    Madera NVARCHAR(255),
    Relleno NVARCHAR(255)
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
    Tiempo_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Ubicacion_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Ubicacion,
    Sucursal_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Sucursal,
    Turno_Ventas_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Turno_Ventas,
    Total_Ingresos DECIMAL(38,2) NOT NULL,
    Cantidad_Facturas BIGINT NOT NULL,
    Promedio_Factura DECIMAL(38,2) NOT NULL,
    Promedio_Tiempo_Fab DECIMAL(6,2) NOT NULL,
    PRIMARY KEY (Tiempo_Id, Ubicacion_Id, Sucursal_Id, Turno_Ventas_Id)
)

CREATE TABLE DATA_DEALERS.BI_Hechos_Ventas_Detalles ( -- Relaciona cada detalle de venta con modelo_sillon
    Modelo_Sillon_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Modelo_Sillon,
    Rango_Etario_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Rango_Etario_Clientes,
    Tiempo_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Ubicacion_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Ubicacion,
    Detalle_Cantidad BIGINT NOT NULL,
    PRIMARY KEY (Modelo_Sillon_Id, Rango_Etario_Id, Tiempo_Id, Ubicacion_Id)
)

CREATE TABLE DATA_DEALERS.BI_Hechos_Compras (
    Tiempo_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Sucursal_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Sucursal,
    Tipo_Material_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Tipo_Material,
    Total_Egresos DECIMAL(38,2) NOT NULL,
    Cantidad_Compras BIGINT NOT NULL,
    PRIMARY KEY (Tiempo_Id, Sucursal_Id, Tipo_Material_Id)
)

CREATE TABLE DATA_DEALERS.BI_Hechos_Pedidos (
    Tiempo_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Sucursal_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Sucursal,
    Estado_Pedido_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Estado_Pedido,
    Turno_Ventas_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Turno_Ventas,
    Cantidad_Pedidos BIGINT NOT NULL,
    Porc_Conversion DECIMAL(5,2) NOT NULL,
    PRIMARY KEY (Tiempo_Id, Sucursal_Id, Estado_Pedido_Id, Turno_Ventas_Id)
)

CREATE TABLE DATA_DEALERS.BI_Hechos_Envios (
    Tiempo_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Tiempo,
    Ubicacion_Id BIGINT REFERENCES DATA_DEALERS.BI_Dimension_Ubicacion,
    Cantidad_Envios BIGINT NOT NULL,
    Cantidad_Cumplidos BIGINT NOT NULL,
    Total_Costo_Envios DECIMAL(38,2) NOT NULL,
    PRIMARY KEY (Tiempo_Id, Ubicacion_Id)
)

-- 1. Ganancias: Total de ingresos (facturación) - total de egresos (compras), por
--     cada mes, por cada sucursal.
--     [VENTAS, COMPRAS]

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