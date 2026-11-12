-- Intentos por fecha y estado.
-- Etapa inicial: filtro hasta 2026-10-02. Etapa final: filtro ampliado hasta 2026-10-03.
SELECT
  fecha,
  estado,
  COUNT(*) AS total_intentos
FROM entregas
WHERE fecha BETWEEN '2026-10-01' AND '2026-10-03'
GROUP BY fecha, estado
ORDER BY fecha ASC, estado ASC
