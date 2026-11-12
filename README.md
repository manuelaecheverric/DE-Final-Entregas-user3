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
Sin cambiar infraestructura ni propiedades de la tabla, y sin crawlers, `MSCK REPAIR`, `ALTER TABLE ADD PARTITION` ni particiones en Terraform. Se ejecutó `verificacion_tercer_dia.sql` (6 registros del día 3, 18 en total) y se volvieron a ejecutar las consultas de intentos y porcentaje con el filtro ampliado hasta 2026-10-03. Resultados en `resultados/final/`, iguales a los esperados.

Todas las ejecuciones (etapa, SQL, id, resultado) están en `evidencias/ejecuciones_athena.csv`.

### 4. Limpieza
```powershell
aws s3 rm "s3://$b" --recursive          # vaciar el bucket (datos y resultados de Athena)
terraform -chdir=infraestructura plan -destroy   # 5 to destroy (los 2 prefijos ya se borraron al vaciar el bucket)
cmd /c "terraform -chdir=infraestructura destroy -auto-approve -no-color > evidencias\eliminacion_terraform.txt 2>&1"
```

## Costos
La facturación de la cuenta no es visible para los estudiantes, así que el costo se midió con `DataScannedInBytes`: cada consulta escaneó 949 bytes. Athena cobra USD 5/TB con un mínimo de 10 MB por consulta, por lo que el total es menor que USD 0,001. Ningún recurso tiene cobro por hora y todo se eliminó al final.

## Evidencias
- `evidencias/aplicacion_terraform.txt`, `evidencias/outputs.json`: salida del apply y outputs.
- `evidencias/ejecuciones_athena.csv`: ids de ejecución antes y después del día 3.
- `evidencias/eliminacion_terraform.txt`: salida del destroy.
- Capturas `.png` de apply, S3, Athena y consultas recientes.
- En los archivos de texto, el número de cuenta AWS se reemplazó por `<ID_CUENTA>`; en las capturas se ocultó.

## Estructura
README.md .gitignore respuestas.md
infraestructura/ consultas/ resultados/inicial/ resultados/final/ evidencias/
data/ resultados_esperados/ (material del enunciado, sin modificar)
