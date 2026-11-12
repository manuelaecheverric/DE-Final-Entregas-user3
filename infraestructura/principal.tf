terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  nombre_bucket    = "${var.prefijo}-${var.sufijo}"
  nombre_base      = replace("${var.prefijo}_${var.sufijo}", "-", "_")
  nombre_workgroup = "${var.prefijo}-${var.sufijo}"
}

# ---------- S3: bucket privado ----------
resource "aws_s3_bucket" "datos" {
  bucket        = local.nombre_bucket
  force_destroy = false # se vacia manualmente antes del destroy, como pide el enunciado
}

resource "aws_s3_bucket_public_access_block" "datos" {
  bucket                  = aws_s3_bucket.datos.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Prefijos (objetos vacios terminados en "/")
resource "aws_s3_object" "prefijo_entregas" {
  bucket  = aws_s3_bucket.datos.id
  key     = "entregas/"
  content = ""
}

resource "aws_s3_object" "prefijo_resultados_athena" {
  bucket  = aws_s3_bucket.datos.id
  key     = "resultados-athena/"
  content = ""
}

# ---------- Glue Data Catalog ----------
resource "aws_glue_catalog_database" "entregas" {
  name        = local.nombre_base
  description = "Examen final DE - intentos de entrega"
}

resource "aws_glue_catalog_table" "entregas" {
  name          = var.nombre_tabla
  database_name = aws_glue_catalog_database.entregas.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "EXTERNAL"               = "TRUE"
    "classification"         = "csv"
    "skip.header.line.count" = "1"

    # Partition projection: Athena calcula las particiones, no se registran
    "projection.enabled"             = "true"
    "projection.fecha.type"          = "date"
    "projection.fecha.format"        = "yyyy-MM-dd"
    "projection.fecha.range"         = "${var.fecha_inicio},${var.fecha_fin}"
    "projection.fecha.interval"      = "1"
    "projection.fecha.interval.unit" = "DAYS"
    "storage.location.template"      = "s3://${aws_s3_bucket.datos.bucket}/entregas/fecha=$${fecha}/"
  }

  partition_keys {
    name = "fecha"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.datos.bucket}/entregas/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim"          = ","
        "serialization.format" = ","
      }
    }

    columns {
      name = "id_envio"
      type = "string"
    }
    columns {
      name = "ciudad"
      type = "string"
    }
    columns {
      name = "transportadora"
      type = "string"
    }
    columns {
      name = "estado"
      type = "string"
    }
    columns {
      name = "duracion_minutos"
      type = "int"
    }
  }
}

# ---------- Athena ----------
resource "aws_athena_workgroup" "entregas" {
  name          = local.nombre_workgroup
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false
    bytes_scanned_cutoff_per_query     = 104857600 # 100 MB: tope de costo por consulta

    result_configuration {
      output_location = "s3://${aws_s3_bucket.datos.bucket}/resultados-athena/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}
