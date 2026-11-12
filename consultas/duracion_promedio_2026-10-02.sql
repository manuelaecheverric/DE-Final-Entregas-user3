-- Duracion promedio de las entregas exitosas del 2026-10-02.
-- Se excluyen los intentos fallidos (duracion 0) filtrando estado = 'entregado'.
SELECT
  fecha,
  CAST(ROUND(AVG(CAST(duracion_minutos AS DOUBLE)), 2) AS DECIMAL(10,2)) AS duracion_promedio_minutos
FROM entregas
WHERE fecha = '2026-10-02'
  AND estado = 'entregado'
GROUP BY fecha
