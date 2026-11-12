# Respuestas conceptuales

## 1. ¿Por qué el día 3 se pudo consultar sin crear una partición nueva?

Porque la tabla `entregas` usa **partition projection**. En vez de guardar cada partición en el Glue Data Catalog, la tabla trae en sus propiedades la regla para calcularlas: `projection.fecha.type = date`, formato `yyyy-MM-dd`, rango `2026-10-01,2026-10-03`, intervalo de 1 día, y la plantilla `storage.location.template = s3://<bucket>/entregas/fecha=${fecha}/`.

Cuando Athena ejecuta una consulta, genera las fechas del rango (o solo las del filtro `WHERE fecha ...`) y arma la ruta de S3 de cada una con la plantilla. Como el 2026-10-03 estaba dentro del rango desde el `terraform apply` inicial, bastó con subir el archivo a `entregas/fecha=2026-10-03/entregas.csv`: Athena ya "sabía" dónde buscarlo.

Evidencia: no se usó crawler, `MSCK REPAIR TABLE` ni `ALTER TABLE ADD PARTITION`, y Terraform se aplicó una sola vez (`evidencias/aplicacion_terraform.txt`). Aun así, la ejecución `45ac5123-1d76-49a8-948e-c7713136b823` (`consultas/verificacion_tercer_dia.sql`) devolvió 6 registros del día 3 y 18 en total (`resultados/final/verificacion_tercer_dia.csv`). Las consultas finales coinciden con `resultados_esperados/`.

## 2. ¿Qué se necesitaría para consultar un archivo del 4 de octubre?

Subir el archivo no alcanza, porque el 2026-10-04 está **fuera del rango** de la proyección (termina en 2026-10-03). Athena no genera esa fecha, así que la consulta no devolvería esos registros.

Habría que:
1. Ampliar el rango de la proyección en Terraform, por ejemplo cambiando la variable `fecha_fin` a `2026-10-04` (o usar un rango abierto como `2026-10-01,NOW`), y hacer `terraform plan` y `terraform apply`. Es una actualización en el mismo lugar de las propiedades de la tabla, sin reemplazarla.
2. Subir el archivo a `s3://<bucket>/entregas/fecha=2026-10-04/entregas.csv`, respetando la plantilla.
3. Ampliar el filtro de fechas de las consultas hasta `2026-10-04`.

Tampoco haría falta registrar particiones ni usar `MSCK REPAIR`.
