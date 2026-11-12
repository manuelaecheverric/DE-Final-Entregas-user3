-- Porcentaje de exito por fecha y ciudad.
-- Etapa inicial: filtro hasta 2026-10-02. Etapa final: filtro ampliado hasta 2026-10-03.
-- Exito = estado 'entregado'; denominador = todos los intentos (todos los estados).
-- CAST a DOUBLE evita la division entera; DECIMAL(5,2) fuerza dos decimales.
SELECT
  fecha,
  ciudad,
  CAST(ROUND(100 * CAST(SUM(CASE WHEN estado = 'entregado' THEN 1 ELSE 0 END) AS DOUBLE) / COUNT(*), 2) AS DECIMAL(5,2)) AS porcentaje_exito
FROM entregas
WHERE fecha BETWEEN '2026-10-01' AND '2026-10-03'
GROUP BY fecha, ciudad
ORDER BY fecha ASC, ciudad ASC
