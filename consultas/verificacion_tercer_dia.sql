-- Verificacion del dia 3 (2026-10-03) sin registrar particiones.
-- Athena ejecuta una sentencia por ejecucion: cada consulta se lanza por separado
-- y su resultado se guarda en un CSV distinto dentro de resultados/final/.

-- 1) Los seis registros del 2026-10-03 -> resultados/final/verificacion_tercer_dia.csv
SELECT
  id_envio,
  ciudad,
  transportadora,
  estado,
  duracion_minutos,
  fecha
FROM entregas
WHERE fecha = '2026-10-03'
ORDER BY id_envio ASC;

-- 2) Conteos por estado del 2026-10-03 -> resultados/final/verificacion_tercer_dia_conteo_estado.csv
SELECT
  fecha,
  estado,
  COUNT(*) AS total_intentos
FROM entregas
WHERE fecha = '2026-10-03'
GROUP BY fecha, estado
ORDER BY estado ASC;

-- 3) Registros del dia 3 y total de la tabla (se esperan 6 y 18) -> resultados/final/verificacion_tercer_dia_totales.csv
SELECT
  COUNT_IF(fecha = '2026-10-03') AS registros_tercer_dia,
  COUNT(*) AS registros_totales
FROM entregas
WHERE fecha BETWEEN '2026-10-01' AND '2026-10-03';
