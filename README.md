# Examen final Ingeniería de Datos: Entregas (AWS + Terraform + Athena)

Solución del punto 1 del examen ([enunciado](https://github.com/smm-0216/DE-Final-Entregas)).
Autora: Manuela Echeverri Castrillón (usuario IAM `de-gr01-user-3`, grupo `de-gr01-students`).
Trabajo realizado con apoyo de IA (Claude); el chat se comparte con el docente.

## Arquitectura
Los CSV diarios se guardan en `s3://de-final-entregas-gr01-user3/entregas/fecha=yyyy-MM-dd/entregas.csv`. Una tabla externa de Glue (`de_final_entregas_gr01_user3.entregas`) con **partition projection** sobre `fecha` los expone a Athena. El workgroup `de-final-entregas-gr01-user3` escribe los resultados en `resultados-athena/` del mismo bucket.

## Requisitos previos
- Terraform >= 1.5 (usado: 1.17.2), provider `hashicorp/aws ~> 6.0` (instalado 6.73.0, fijado en `.terraform.lock.hcl`).
- AWS CLI v2 con credenciales que tengan permisos sobre S3, Glue y Athena.
- Región: `us-east-2`.
- Cuenta AWS compartida: todos los nombres llevan el sufijo `gr01-user3` (variable `sufijo`).
- Repositorio clonado con `git clone -c core.autocrlf=false` para que los CSV conserven LF (un `\r` dañaría `duracion_minutos`).

## Recursos (infraestructura/)
| Archivo | Contenido |
|---|---|
| `principal.tf` | Bucket S3 privado + bloqueo de acceso público, prefijos `entregas/` y `resultados-athena/`, base de datos Glue, tabla externa CSV (5 columnas, omite encabezado, `fecha` string como partición, proyección `date` `yyyy-MM-dd` del 2026-10-01 al 2026-10-03, intervalo 1 día) y workgroup de Athena (configuración obligatoria, tope de 100 MB por consulta). |
| `variables.tf` | Región, prefijo, sufijo, nombre de tabla y rango de fechas. |
| `salidas.tf` | Bucket, base de datos, tabla, workgroup y ubicaciones. |

## Pasos
### 1. Desplegar
```powershell
terraform -chdir=infraestructura init
terraform -chdir=infraestructura plan -out=tfplan      # Plan: 7 to add
cmd /c "terraform -chdir=infraestructura apply -no-color tfplan > evidencias\aplicacion_terraform.txt 2>&1"
cmd /c "terraform -chdir=infraestructura output -json > evidencias\outputs.json"
```

### 2. Etapa inicial: días 1 y 2 (archivo por archivo, sin carga recursiva)
```powershell
$b = "de-final-entregas-gr01-user3"
aws s3 cp "data\entregas\fecha=2026-10-01\entregas.csv" "s3://$b/entregas/fecha=2026-10-01/entregas.csv"
aws s3 cp "data\entregas\fecha=2026-10-02\entregas.csv" "s3://$b/entregas/fecha=2026-10-02/entregas.csv"
```
`SELECT COUNT(*) FROM entregas` devolvió 12. Se ejecutaron en el workgroup (con `--query-string file://consultas/<archivo>.sql`) las consultas `intentos_por_fecha_estado.sql`, `porcentaje_exito_por_fecha_ciudad.sql` (filtro hasta 2026-10-02) y `duracion_promedio_2026-10-02.sql`. Cada resultado se descargó de `resultados-athena/<id>.csv`, se le quitaron las comillas de Athena, se guardó en `resultados/inicial/` (UTF-8 sin BOM, LF) y se comparó con `resultados_esperados/`: todos iguales.

### 3. Etapa final: día 3
```powershell
aws s3 cp "data\entregas\fecha=2026-10-03\entregas.csv" "s3://$b/entregas/fecha=2026-10-03/entregas.csv"
```
Sin cambiar infraestructura ni propiedades de la tabla, y sin crawlers, `MSCK REPAIR`, `ALTER TABLE ADD PARTITION` ni particiones en Terraform. Se ejecutó la consulta de totales de `verificacion_tercer_dia.sql` (6 registros del día 3, 18 en total; `resultados/final/verificacion_tercer_dia_totales.csv`) y se volvieron a ejecutar las consultas de intentos y porcentaje con el filtro ampliado hasta 2026-10-03. Resultados en `resultados/final/`, iguales a los esperados.

Todas las ejecuciones (etapa, SQL, id, resultado) están en `evidencias/ejecuciones_athena.csv`.

### 4. Limpieza
```powershell
aws s3 rm "s3://$b" --recursive          # vaciar el bucket (datos y resultados de Athena)
terraform -chdir=infraestructura plan -destroy   # 5 to destroy (los 2 prefijos ya se borraron al vaciar el bucket)
cmd /c "terraform -chdir=infraestructura destroy -auto-approve -no-color > evidencias\eliminacion_terraform.txt 2>&1"
```

### 5. Re-verificación del día 3 (despliegue adicional)
Al revisar la entrega se detectó que `resultados/final/verificacion_tercer_dia.csv` solo tenía los conteos (6 y 18), y el enunciado pide guardar ahí **los seis registros** del día 3. Como los recursos ya se habían eliminado, se volvió a desplegar exactamente el mismo código Terraform, sin ningún cambio, para completar esa evidencia:

1. `terraform plan` (7 to add) y `apply` → `evidencias/aplicacion_terraform_reverificacion.txt`.
2. Carga archivo por archivo, en orden: día 1, día 2 y día 3 (`aws s3 cp`, sin carga recursiva).
3. Se ejecutaron en el workgroup las consultas 1 y 2 de `consultas/verificacion_tercer_dia.sql`. Athena ejecuta una sentencia por ejecución, así que cada una se lanzó por separado:
   - registros del 2026-10-03 → `resultados/final/verificacion_tercer_dia.csv` (6 filas);
   - conteo por estado del 2026-10-03 → `resultados/final/verificacion_tercer_dia_conteo_estado.csv` (3, 1 y 2, igual que en `intentos_por_fecha_estado.csv`).
4. Vaciado del bucket y `terraform destroy` → `evidencias/eliminacion_terraform_reverificacion.txt`.

La tabla, sus propiedades y el rango de proyección no se modificaron. Tampoco se usaron crawlers, `MSCK REPAIR` ni `ALTER TABLE ADD PARTITION`. Los ids de ejecución quedaron registrados con etapa `final` en `evidencias/ejecuciones_athena.csv`.

## Costos
La facturación de la cuenta no es visible para los estudiantes, así que el costo se midió con `DataScannedInBytes`: cada consulta escaneó 949 bytes. Athena cobra USD 5/TB con un mínimo de 10 MB por consulta, por lo que el total es menor que USD 0,001. Ningún recurso tiene cobro por hora y todo se eliminó al final.

## Evidencias
- `evidencias/aplicacion_terraform.txt`, `evidencias/outputs.json`: salida del apply y outputs.
- `evidencias/ejecuciones_athena.csv`: ids de ejecución antes y después del día 3.
- `evidencias/eliminacion_terraform.txt`: salida del destroy.
- `evidencias/aplicacion_terraform_reverificacion.txt` y `evidencias/eliminacion_terraform_reverificacion.txt`: apply y destroy del despliegue adicional de la sección 5.
- Capturas `.png` de apply, S3, Athena y consultas recientes.
- En los archivos de texto, el número de cuenta AWS se reemplazó por `<ID_CUENTA>`; en las capturas se ocultó.

## Estructura
README.md .gitignore respuestas.md
infraestructura/ consultas/ resultados/inicial/ resultados/final/ evidencias/
data/ resultados_esperados/ (material del enunciado, sin modificar)
