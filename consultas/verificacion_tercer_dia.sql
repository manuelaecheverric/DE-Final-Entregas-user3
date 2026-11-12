-- Verifica que el dia 3 es consultable sin registrar particiones:
-- se esperan 6 registros del 2026-10-03 y 18 en total.
SELECT
  COUNT_IF(fecha = '2026-10-03') AS registros_tercer_dia,
  COUNT(*) AS registros_totales
FROM entregas
WHERE fecha BETWEEN '2026-10-01' AND '2026-10-03'
