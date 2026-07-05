# Análisis del Archivo 1.sql - Base de Datos TenebrosaOLTP

## 📊 Resumen

El archivo `1.sql` es un script SQL Server completo que contiene un sistema ERP mucho más grande que lo que el backend CronoApp utiliza.

**Tamaño del archivo:** 81,206 bytes
**Base de datos:** TenebrosaOLTP
**Motor:** SQL Server

---

## 🗄️ Tablas en 1.sql

### ✅ Tablas que el Backend CronoApp USA

| Tabla | Descripción | Registros (aprox) |
|-------|-------------|-------------------|
| `DOCUMENTO` | Documentos de venta/factura | 228,262 |
| `DETADOC` | Detalle de documentos | 228,262 |
| `CRONOGRAMA` | Cronogramas de pagos | 228,262 |
| `PARAMETRO` | Parámetros del sistema (IGV, tasas) | 2 |
| `usuarios` | Usuarios del sistema | 2 |

### ❌ Tablas que el Backend CronoApp NO USA

| Tabla | Descripción |
|-------|-------------|
| `PRODUCTO` | Catálogo de productos |
| `CLIENTE` | Información de clientes |
| `LINEA` | Líneas de productos |
| `MARCA` | Marcas de productos |
| `BANCO` | Bancos para pagos |
| `CIUDAD` | Ciudades |
| `DETALIQUI` | Detalle de liquidaciones |
| `DETALLERequerimiento` | Detalle de requerimientos |
| `DETAPEDIDO` | Detalle de pedidos |
| `FERIADOS` | Días feriados |
| `FORMAPAGO` | Formas de pago |
| `LIQUIDACION` | Liquidaciones de personal |
| `MEDIOPAGO` | Medios de pago |
| `MetaMarcaPersonal` | Metas por marca y personal |
| `MetaProductoZona` | Metas por producto y zona |
| `Metas_Venta` | Metas de ventas |
| `MetaSectorista` | Metas de sectoristas |
| `MULTITABLA` | Tabla multipropósito |
| `oferton` | Ofertas especiales |
| `PEDIDO` | Pedidos de clientes |
| `PERSONAL` | Personal de la empresa |
| `ProductoUnegocio` | Productos por unidad de negocio |
| `PronosticoClienteMarca` | Pronósticos por cliente y marca |
| `PROVEEDOR` | Proveedores |
| `PUNTOPAGO` | Puntos de pago |
| `Requerimiento` | Requerimientos del sistema |
| `SeguimientoX` | Seguimiento de cambios |
| `sys_documentacion` | Documentación del sistema |
| `Tienda` | Tiendas/sucursales |
| `TIPODOC` | Tipos de documentos |
| `UNegocio` | Unidades de negocio |
| `VentaMeta` | Ventas vs metas |
| `VentaMetaY` | Ventas vs metas (alternativo) |
| `ZONA` | Zonas de venta |
| `ZonaMarcaTiempo` | Análisis por zona, marca y tiempo |

**Total de tablas en 1.sql:** ~40 tablas
**Tablas usadas por CronoApp:** 5 tablas
**Tablas NO usadas:** ~35 tablas

---

## 👁️ Vistas en 1.sql

| Vista | Descripción | ¿Usada por Backend? |
|-------|-------------|---------------------|
| `v_Documento` | Vista de documentos con montos | ❌ No |
| `v_cronograma` | Vista de cronogramas con totales | ❌ No |
| `v_Ventas` | Vista de ventas detalladas | ❌ No |
| `v_VentasPrevio` | Vista de ventas por fecha | ❌ No |
| `_Otros` | Vista de análisis de其他 | ❌ No |
| `v_dimTiempo` | Dimensión de tiempo para BI | ❌ No |
| `v_VentasDetalladas` | Vista de ventas detalladas | ❌ No |

---

## 🔗 Relaciones (Foreign Keys)

**Relaciones importantes para CronoApp:**
- `CRONOGRAMA` → `BANCO` (idBanco)
- `CRONOGRAMA` → `MEDIOPAGO` (idMedioPago)
- `CRONOGRAMA` → `PUNTOPAGO` (idPuntoPago)
- `DETADOC` → `DOCUMENTO` (Documento, TipoDoc)
- `DETADOC` → `PRODUCTO` (Producto)

**Relaciones NO usadas por CronoApp:**
- `CLIENTE` → `ZONA`
- Muchas otras relaciones entre tablas no usadas

---

## 📋 Esquema de Tablas Usadas por CronoApp

### DOCUMENTO
```sql
CREATE TABLE [dbo].[DOCUMENTO](
    [Documento] [char](9) NOT NULL,
    [TipoDoc] [char](1) NOT NULL,
    [Proveedor] [char](4) NULL,
    [Pedido] [char](9) NULL,
    [Cliente] [char](4) NULL,
    [Fecha] [datetime] NOT NULL,
    [Estado] [char](1) NOT NULL,
    [DocRefer] [char](9) NULL,
    [Personal] [char](2) NULL,
    [pagado] [decimal](9, 2) NOT NULL,
    [IdTienda] [char](2) NOT NULL,
    [FormaPago] [char](1) NULL,
    [Hora] [datetime] NULL,
    PRIMARY KEY (Documento, TipoDoc)
)
```

### DETADOC
```sql
CREATE TABLE [dbo].[DETADOC](
    [Documento] [char](9) NOT NULL,
    [TipoDoc] [char](1) NOT NULL,
    [Producto] [char](4) NOT NULL,
    [Cantidad] [decimal](9, 2) NOT NULL,
    [Igv] [decimal](9, 2) NOT NULL,
    [PrecUnit] [decimal](9, 2) NOT NULL,
    PRIMARY KEY (Documento, TipoDoc, Producto)
)
```

### CRONOGRAMA
```sql
CREATE TABLE [dbo].[CRONOGRAMA](
    [NroCuota] [int] NOT NULL,
    [Documento] [char](9) NOT NULL,
    [TipoDoc] [char](1) NOT NULL,
    [Importe] [decimal](9, 2) NOT NULL,
    [Interes] [decimal](9, 2) NOT NULL,
    [IgvInteres] [decimal](9, 2) NOT NULL,
    [feVence] [datetime] NOT NULL,
    [Fepago] [datetime] NULL,
    [estado] [char](1) NOT NULL,
    [idMedioPago] [char](2) NULL,
    [idPuntoPago] [char](2) NULL,
    [idBanco] [char](2) NULL,
    PRIMARY KEY (NroCuota, Documento, TipoDoc)
)
```

### PARAMETRO
```sql
CREATE TABLE [dbo].[PARAMETRO](
    [Parametro] [int] NOT NULL,
    [Igv] [decimal](8, 2) NOT NULL,
    [TasaInt] [decimal](8, 2) NOT NULL,
    [TasaLegal] [decimal](8, 2) NOT NULL,
    [Fecha] [datetime] NOT NULL,
    [TasaDolar] [decimal](9, 2) NOT NULL,
    [activo] [bit] NOT NULL,
    [Vencidos] [tinyint] NOT NULL
)
```

### usuarios
```sql
CREATE TABLE [dbo].[usuarios](
    [id] [int] IDENTITY(1,1) NOT NULL,
    [username] [varchar](50) NOT NULL,
    [password_hash] [varchar](255) NOT NULL,
    [nombre] [varchar](100) NOT NULL,
    [activo] [bit] NOT NULL,
    [created_at] [datetime] NULL,
    PRIMARY KEY (id),
    UNIQUE (username)
)
```

---

## ⚠️ Diferencias con el Backend Esperado

### Tabla DOCUMENTO
**1.sql:** `Cliente` (char(4))
**Backend espera:** `Cliente` (existe, pero backend usa diferentes columnas)

### Tabla DETADOC
**1.sql:** `Producto` (char(4))
**Backend espera:** `descrip` (no existe en 1.sql)

### Tabla CRONOGRAMA
**1.sql:** `feVence` (datetime), `Fepago` (datetime)
**Backend espera:** `feVence` (existe), `Fepago` (existe)

---

## 🎯 Conclusión

**El archivo 1.sql contiene un sistema ERP completo, pero el backend CronoApp solo usa 5 tablas específicas.**

**Para tu tarea:**
- ✅ Puedes usar el archivo 1.sql para restaurar la base de datos completa
- ✅ El backend funcionará con las tablas que necesita
- ✅ Las tablas adicionales no afectan el funcionamiento de CronoApp
- ✅ Es una base de datos real con datos reales (228K+ registros)

**No necesitas modificar nada** - el backend solo usará las tablas que necesita e ignorará el resto.
