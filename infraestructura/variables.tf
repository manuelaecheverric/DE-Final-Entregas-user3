variable "region" {
  description = "Region de AWS donde se despliega todo"
  type        = string
  default     = "us-east-2"
}

variable "prefijo" {
  description = "Prefijo comun de los recursos del examen"
  type        = string
  default     = "de-final-entregas"
}

variable "sufijo" {
  description = "Sufijo unico del estudiante para no chocar en la cuenta compartida"
  type        = string
  default     = "gr01-user3"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.sufijo))
    error_message = "El sufijo solo puede tener minusculas, numeros y guiones."
  }
}

variable "nombre_tabla" {
  description = "Nombre de la tabla externa de Glue"
  type        = string
  default     = "entregas"
}

variable "fecha_inicio" {
  description = "Primera fecha del rango de partition projection (yyyy-MM-dd)"
  type        = string
  default     = "2026-10-01"
}

variable "fecha_fin" {
  description = "Ultima fecha del rango de partition projection (yyyy-MM-dd)"
  type        = string
  default     = "2026-10-03"
}
