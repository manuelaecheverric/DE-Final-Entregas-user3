output "region" {
  value = var.region
}

output "bucket" {
  value = aws_s3_bucket.datos.bucket
}

output "base_datos_glue" {
  value = aws_glue_catalog_database.entregas.name
}

output "tabla_glue" {
  value = aws_glue_catalog_table.entregas.name
}

output "workgroup_athena" {
  value = aws_athena_workgroup.entregas.name
}

output "ubicacion_datos" {
  value = "s3://${aws_s3_bucket.datos.bucket}/entregas/"
}

output "ubicacion_resultados_athena" {
  value = "s3://${aws_s3_bucket.datos.bucket}/resultados-athena/"
}
