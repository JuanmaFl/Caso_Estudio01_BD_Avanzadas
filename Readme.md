# Caso de Estudio 1: Optimización de Big Data en PostgreSQL (EafitShop)

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue?logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED?logo=docker&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-RDS%20%26%20EC2-FF9900?logo=amazonaws&logoColor=white)

**Materia:** Tópicos Especiales en Telemática / Bases de Datos Avanzadas  
**Entrega:** Proyecto 1 - Benchmarking & Performance Tuning  

---

## 1. Objetivo del Trabajo
Implementar, medir y optimizar una base de datos transaccional con un volumen de **5 millones de registros** (Big Data académico), simulando un entorno de comercio electrónico ("EafitShop"). El objetivo central es comparar el rendimiento entre una infraestructura contenerizada (**Docker en EC2**) y un servicio gestionado (**AWS RDS**), aplicando técnicas incrementales (Índices, Particionamiento, Reescritura, Vistas Materializadas) para mitigar cuellos de botella de I/O y CPU.

## 2. Descripción del Caso
El sistema **EafitShop** simula una plataforma con 5 años de histórico operativo, conteniendo:
* **1 Millón** de Clientes.
* **5 Millones** de Órdenes de Compra.
* **20 Millones** de Ítems de pedido.

**El Reto:** El sistema base carece de optimizaciones, generando tiempos de respuesta inaceptables (>20 segundos) en reportes analíticos y bloqueos en operaciones transaccionales debido a *Sequential Scans* (lecturas completas de disco).

## 3. Situación Real Empresarial
Este escenario replica los desafíos de escalabilidad que enfrentan empresas como **Uber** o **Shopify** durante picos de tráfico. Cuando las tablas OLTP crecen exponencialmente, los *JOINs* masivos degradan el servicio. Estudios de ingeniería (como los de *Instagram* migrando a Postgres) demuestran que en la nube, el **costo de I/O aleatorio** (IOPS) en discos de red puede hacer que las consultas mal optimizadas sean más lentas que en un servidor local, obligando al uso de estrategias como **Vistas Materializadas** para reportes o **Sharding**.

### Consulta Q1: Reporte Masivo de Ventas (OLAP)
* **Descripción:** Calcula el total de ingresos y volumen de órdenes agrupadas por ciudad desde una fecha de corte específica.
* **Reto Técnico:** Requiere escanear, filtrar y sumarizar el **100% de la tabla de órdenes recientes** (>20% del total de datos).
* **Justificación en el Trabajo:**
    * Demuestra las limitaciones de los **Índices B-Tree** para lecturas masivas (*Full Table Scans*).
    * Evidencia el **fallo del Particionamiento** para datos "calientes" (*Hot Data*), donde el overhead de gestión supera la ganancia.
    * Justifica la implementación de **Vistas Materializadas** como única solución viable para reportes de Big Data (reducción de 30s a 0.1ms).

### Consulta Q2: Búsqueda Puntual de Cliente (OLTP)
* **Descripción:** Recupera el historial de compras de un usuario específico mediante su correo electrónico.
* **Reto Técnico:** Alta Selectividad (Encontrar 1 registro específico entre 1 millón).
* **Justificación en el Trabajo:**
    * Escenario clásico para demostrar la eficiencia de los **Índices B-Tree**.
    * Permite medir la latencia pura de red entre Docker (Local) y RDS, al ser una consulta de respuesta inmediata (<200ms).

### Consulta Q3: Analítica de Productos (Híbrida/Compleja)
* **Descripción:** Realiza un JOIN de 3 tablas grandes (*Order_Items*, *Products*, *Orders*) filtrando por categoría y rango de fechas.
* **Reto Técnico:** Alto consumo de CPU y I/O para cruzar tablas de **20 millones de registros**.
* **Justificación en el Trabajo:**
    * Escenario ideal para aplicar **Reescritura de Queries (Query Rewriting)** usando CTEs (*Common Table Expressions*) para filtrar antes de unir.
    * Reveló el **cuello de botella de I/O en la Nube (RDS)**: los índices complejos generaron lecturas aleatorias (*Random I/O*) que saturaron el disco EBS, un fenómeno no visible en el SSD local.



## 4. Ambiente Tecnológico Utilizado

Se realizó un Benchmarking comparativo (A/B testing) entre dos arquitecturas:

| Característica | Ambiente A (Local/Docker) | Ambiente B (Nube/RDS) |
| :--- | :--- | :--- |
| **Infraestructura** | AWS EC2 (`t3.large`) | AWS RDS (`db.t4g.micro`) |
| **Almacenamiento** | **SSD NVMe (Local Ephemeral)** | **EBS gp2 (Network Storage)** |
| **Ventaja** | Latencia de disco casi nula. Acceso directo a RAM. | Alta disponibilidad, Backups automáticos, Gestionado. |
| **Desventaja** | Gestión manual de persistencia. | **Latencia de Red en I/O.** IOPS limitados (Capa Gratuita). |

---

## 5. Resumen de Datos y Resultados (Benchmarking)

A continuación, se presentan los tiempos de ejecución medidos con `EXPLAIN (ANALYZE, BUFFERS)`.

### Escenario 1: Reporte Masivo (Q1 - OLAP)
*Consulta de agregación de ventas por ciudad (Full Table Scan).*

| Estado | EC2 (Docker) | AWS RDS | Análisis |
| :--- | :--- | :--- | :--- |
| **Línea Base** | 9,875 ms | 5,198 ms | RDS fue inicialmente más rápido por caché caliente. |
| **Optimizado (Índices)** | 8,849 ms | 5,087 ms | Mejora marginal. Los índices B-Tree no sirven para leer >20% de la tabla. |
| **Optimizado (Vista Mat.)** | **0.215 ms** | **~0.12 ms** | **¡Mejora del 4,000,000%!** La única solución viable. |

### Escenario 2: Búsqueda Puntual (Q2 - OLTP)
*Búsqueda de historial de un cliente específico por email.*

| Estado | EC2 (Docker) | AWS RDS | Análisis |
| :--- | :--- | :--- | :--- |
| **Línea Base** | 5,688 ms | 1,665 ms | Lento (Seq Scan). |
| **Optimizado (Índices)** | **262 ms** | **212 ms** | **Mejora del 95%.** El Índice B-Tree es la solución estándar. |

### Escenario 3: Analítica Compleja (Q3 - Híbrido)
*JOIN de 3 tablas (20M registros) con filtros.*

| Estado | EC2 (Docker) | AWS RDS | Análisis Crítico |
| :--- | :--- | :--- | :--- |
| **Línea Base** | 22,972 ms | 13,762 ms | Uso intensivo de CPU. |
| **Con Índices** | 14,652 ms | **35,732 ms (Regresión)** | **Fenómeno I/O Nube:** El índice forzó saltos aleatorios en el disco EBS, saturando los IOPS. |
| **Reescritura (CTE)** | **2,051 ms** | ~13,800 ms | Al filtrar con CTEs antes del JOIN, Docker voló. RDS mejoró pero el disco sigue siendo el límite. |

---

## 6. Análisis de Técnicas y Performance Tuning

### ¿Por qué falló el Particionamiento en Q1?
Se implementó particionamiento por rangos anuales (`PARTITION BY RANGE`).
* **Resultado:** El tiempo aumentó (9.8s -> ~10s).
* **Causa:** La consulta solicitaba datos recientes (`>= 2023`), lo que involucraba escanear particiones grandes. El *overhead* de gestionar múltiples tablas y unir resultados (*Append*) superó el beneficio del *Partition Pruning*. El particionamiento es efectivo para archivar datos viejos, no necesariamente para acelerar reportes de datos "calientes".

### El problema del I/O en la Nube (RDS)
Se evidenció que en la capa gratuita (`db.t4g.micro` con EBS gp2), las operaciones de **Lectura Aleatoria (Random I/O)** generadas por índices complejos en Q3 son penalizadas severamente por la latencia de red.
* **Ajuste necesario:** Se recomienda ajustar `random_page_cost` a `4.0` (o mayor) en RDS para que el planificador prefiera escaneos secuenciales sobre índices ineficientes en discos lentos.

### La Victoria de la Vista Materializada
Para la Q1, ninguna técnica de tuning (`work_mem`, índices) funcionó.
* **Solución:** Pre-calcular el resultado con `CREATE MATERIALIZED VIEW`.
* **Justificación:** En escenarios empresariales de Business Intelligence, se sacrifica el "tiempo real" absoluto a cambio de latencias de milisegundos para el usuario final.

---

## 7. Referencias y Documentación Consultada
Para el tuning de parámetros (`work_mem`, `shared_buffers`) se consultaron las siguientes fuentes oficiales y guías de mejores prácticas:
* [PostgreSQL Performance Tips](https://www.postgresql.org/docs/current/performance-tips.html)
* [Mydbops: Parameter Tuning Best Practices](https://www.mydbops.com/blog/postgresql-parameter-tuning-best-practices)
* [TigerData: Reduce DB Size](https://www.tigerdata.com/blog/how-to-reduce-your-postgresql-database-size)
* [PostgreSQLConf: Parameters](https://postgresqlco.nf/doc/en/param/)
* [Medium: Ultimate Guide to Tuning](https://medium.com/@ankush.thavali/the-ultimate-guide-to-postgresql-performance-tuning-0d8134256125)

## 8. Líneas de Trabajo Futuro
1.  **Discos Provisionados (io1/io2):** Para mitigar la lentitud en RDS (Q3), se debe migrar a almacenamiento con IOPS garantizados.
2.  **Read Replicas:** Separar la carga de la Q1 (Reportes) a una réplica de lectura para no bloquear transacciones.
3.  **Particionamiento Declarativo:** Implementar particionamiento para *Archiving* (mover datos de 2018-2022 a almacenamiento frío S3/Glacier).

## 9. Declaración de Uso de IA
Este proyecto utilizó **ChatGPT/Gemini** como herramientas de asistencia en ingeniería para:
* Generación de scripts SQL de población de datos sintéticos (`generate_series` y arrays aleatorios).
* Análisis e interpretación de planes de ejecución (`EXPLAIN ANALYZE`) para identificar cuellos de botella.
* Resolución de errores de sintaxis (Casting de tipos ENUM).
* *Nota:* Toda la lógica de optimización, ejecución de pruebas y conclusiones arquitectónicas fueron desarrolladas por el equipo.

---

## 10. Instrucciones de Replicación (DevOps)

Siga estos pasos para replicar los resultados:

### Requisitos
* Docker & Docker Compose
* Cliente PostgreSQL (pgAdmin o DBeaver)

### Pasos
1.  **Clonar Repositorio:**
    ```bash
    git clone [https://github.com/TU_USUARIO/EafitShop-DB-Optimization.git](https://github.com/TU_USUARIO/EafitShop-DB-Optimization.git)
    cd EafitShop-DB-Optimization
    ```

2.  **Iniciar Infraestructura:**
    ```bash
    docker-compose up -d
    ```

3.  **Ejecutar Scripts (En orden):**
    * `src/01_schema.sql`: Crea la estructura limpia.
    * `src/02_generate_data.sql`: Genera 5M de registros ( ~5 min - 10 min).
    * `src/03_baseline_queries.sql`: Ejecutar para medir la línea base.
    * `src/04_optimization_indexes.sql`: Aplica índices B-Tree.
    * `src/06_optimization_advanced.sql`: Crea Vistas Materializadas y aplica Query Rewriting.

4.  **Verificación:**
    Ejecutar `EXPLAIN ANALYZE` sobre la Q1 final para ver el tiempo de **0.2ms**.

---
**Autores:** Camila Martinez, Thomas Buitrago, Juan Manuel Florez.
**Universidad EAFIT - 2026**